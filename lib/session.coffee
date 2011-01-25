# TODO: Greatly improve to support arbitrary storage of session variables within Redis (using hashes)

utils = require('./utils')

UserSession = require('user_session').UserSession

class exports.Session
  
  id_length: 32
  user: null     # Takes a UserSession instance when user is logged in
  attributes: {} # To be stored in the redis session
  
  constructor: (@client) ->
    @cookies = try
      utils.parseCookie(@client.request.headers.cookie)
    catch e
      {}
  
  key: ->
    "session:#{@id}"

  process: (cb) ->
    if @cookies && @cookies.session_id && @cookies.session_id.length == @id_length
      R.hgetall 'session:' + @cookies.session_id, (err, @data) =>
        if err or @data == null
          @create(cb)
        else
          @id = @cookies.session_id
          @assignUser(@data.user_id.toString()) if @data.user_id
          cb(null, @)
    else
      @create(cb)

  create: (cb) ->
    @id = utils.randomString(@id_length)
    @data = {}
    @data.created_at = Number(new Date())
    R.hset @key(), 'created_at', @data.created_at, (err, response) =>
      @newly_created = true
      cb(err, @)
      

  # Users

  loggedIn: ->
    @user?
      
  assignUser: (user_id) ->
    return null unless user_id
    @user = new UserSession(user_id, @)
    @

  authenticate: (module_name, params, cb) ->
    klass = require(module_name).Authentication
    auth = new klass
    auth.authenticate params, cb

  logout: (cb) ->
    @user.destroy()
    @user = null
    @create (err, new_session) -> cb(null, new_session)    


  # AUTH - rip out
  save: ->
    R.hset @key(), 'user_id', @user.id if @user



