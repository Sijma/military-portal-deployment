local core = require("apisix.core")
local cjson = require("cjson.safe")
local ngx = ngx

local plugin_name = "app-auth"

local schema = {
    type = "object",
    properties = {
        role = {
            type = "string",
            enum = {"any", "citizen", "officer", "admin"}
        },
        respond_with_identity = { type = "boolean", default = false }
    },
    required = {"role"}
}

local _M = {
    version = 1.0,
    priority = 2000, -- run after OIDC and before traffic-split in the access phase
    name = plugin_name,
    schema = schema
}

function _M.check_schema(conf)
    return core.schema.check(schema, conf)
end

-- Decodes the base64 userinfo that oidc adds.
local function get_userinfo(ctx)
    local headers = core.request.headers(ctx)
    local raw = headers["X-Userinfo"]

    if not raw then
        return nil, "missing X-Userinfo"
    end

    local decoded = ngx.decode_base64(raw)
    if not decoded then
        return nil, "invalid base64"
    end

    local info = cjson.decode(decoded)
    if not info then
        return nil, "invalid json"
    end

    return info
end

-- Require one unambiguous application role from the realm roles.
local function get_role(info)
    local recognized_roles = {}
    local role_count = 0

    if info.realm_access and type(info.realm_access.roles) == "table" then
        for _, r in ipairs(info.realm_access.roles) do
            if (r == "admin" or r == "officer" or r == "citizen")
                and not recognized_roles[r]
            then
                recognized_roles[r] = true
                role_count = role_count + 1
            end
        end
    end

    if role_count == 0 then
        return nil, "no valid role found in identity token"
    end

    if role_count > 1 then
        return nil, "multiple application roles found in identity token"
    end

    for role in pairs(recognized_roles) do
        return role
    end
end

local function is_allowed(user_role, required_role)
    return user_role == required_role
end

function _M.access(conf, ctx)
    local info, err = get_userinfo(ctx)
    if not info then
        core.response.set_header("Content-Type", "application/json")
        return 401, cjson.encode({ message = err })
    end

    local role, role_err = get_role(info)
    if not role then
        core.response.set_header("Content-Type", "application/json")
        return 403, cjson.encode({ message = role_err })
    end

    if conf.role ~= "any" then
        if not is_allowed(role, conf.role) then
            core.response.set_header("Content-Type", "application/json")
            return 403, cjson.encode({ message = "role '" .. conf.role .. "' required" })
        end
    end

    if conf.respond_with_identity then
        core.response.set_header("Content-Type", "application/json")
        return 200, cjson.encode({
            authenticated = true,
            userId = info.sub or "",
            email = info.email or "",
            role = role,
            amka = info.amka or ""
        })
    end

    -- Replace any client-supplied identity values with the authenticated claims.
    core.request.set_header(ctx, "X-Userinfo", nil)

    core.request.set_header(ctx, "X-User-Id", info.sub or "")
    core.request.set_header(ctx, "X-User-Email", info.email or "")
    core.request.set_header(ctx, "X-User-Role", role)
    core.request.set_header(ctx, "X-User-Amka", info.amka or "")
end

return _M
