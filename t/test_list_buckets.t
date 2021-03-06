use Test::Nginx::Socket::Lua 'no_plan';


our $HttpConfig = qq{
    lua_package_path 'lib/?.lua;/usr/local/s2/current/nginx/conf/lua/?.lua;/usr/local/s2/current/nginx/conf/lua/dep/?.lua;;';
    lua_package_cpath 'lib/?.so;/usr/local/s2/current/nginx/conf/lua/lib/?.so;;';
};

no_long_string();
$ENV{TEST_NGINX_ACCESS_KEY} = '"ziw5dp1alvty9n47qksu"';
$ENV{TEST_NGINX_SECRET_KEY} = '"V+ZTZ5u5wNvXb+KP5g0dMNzhMeWe372/yRKx4hZV"';
$ENV{TEST_NGINX_ENDPOINT} = '"127.0.0.1"';
run_tests();

__DATA__

=== TEST 1: test list buckets

--- http_config eval: $::HttpConfig
--- config
location = /t {
    rewrite_by_lua_block {
        local s3_client = require('resty.aws_s3.client')
        local tableutil = require('acid.tableutil')
        local client = s3_client.new(
                       $TEST_NGINX_ACCESS_KEY,
                       $TEST_NGINX_SECRET_KEY,
                       $TEST_NGINX_ENDPOINT)

        local bucket_name = 'test-bucket-' .. tostring(math.random(10000, 99999))

        local resp, err, errmsg = client:create_bucket(
                {Bucket=bucket_name})
        if err ~= nil then
            ngx.say(string.format('failed to create bucket: %s, %s', err, errmsg))
            ngx.exit(ngx.HTTP_OK)
        else
            ngx.say('bucket created')
        end

        local resp, err, errmsg = client:list_buckets()
        if err ~= nil then
            ngx.say(string.format('failed to list buckets: %s, %s', err, errmsg))
            ngx.exit(ngx.HTTP_OK)
        end
        ngx.say('length >= 1: ' .. tostring(#resp.Buckets >= 1))
        ngx.say('Name is string: ' .. tostring(type(resp.Buckets[1].Name) == 'string'))

        local resp, err, errmsg = client:delete_bucket(
                {Bucket=bucket_name})
        if err ~= nil then
            ngx.say(string.format('failed to delete bucket: %s, %s', err, errmsg))
            ngx.exit(ngx.HTTP_OK)
        else
            ngx.say('bucket deleted')
        end
    }
}
--- request
GET /t

--- timeout: 15
--- response_body_like chomp
bucket created
length >= 1: true
Name is string: true
bucket deleted
