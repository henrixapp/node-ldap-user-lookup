###
(c) 2014, Henrik Reinstädtler
The use of this software is granted without any liability.
You should use this software with a correct options object, that contains a
subobject, that is compatible with ldapjs, like following:

{
connection :{
url:'ldap://127.0.0.1:389'
}
adminDn:'cn=admin,dc=example,dc=org',
adminPassword:'secret',
    searchBase:'ou=People,dc=example,dc=org',
    searchFilter:function(id) {
      return "(uidNumber=" + id + ")";
    }
    converter:function(value){
    return value;//Please Update!
  }
}
searchFilter shall be a function that takes ONE argument and returns the right
search string
You can lookup a user by a function with callback and error, the called value
can be "undefined"

converter is a function to "Convert" the ldapobject to your Definitions in your
App, a ldap objects looks like:
{"dn":"uid=lukas,ou=People,dc=development,dc=informatik","controls":[],
"uid":"lukas","cn":"Test User","objectClass":["account","posixAccount","top"],
"loginShell":"/bin/bash","uidNumber":"1001","gidNumber":"1001",
"homeDirectory":"/home/lukas","gecos":"Test user,room 1,,",
"userPassword":"{SSHA}KlLxdcoepNbTry4Ezvf1CtXTrfmzvUIU"}
###
ldap = require 'ldapjs'
assert = require 'assert'
module.exports =(opts)->
  class LDAPLookup
    constructor:(options)->
      throw "no options given" if !options
      @options = options
      @client = ldap.createClient options.connection
      @client.bind(options.adminDn,options.adminPassword,(err)->
        assert.ifError err
        )
      ###
      Searches for a user with the given ID in the normal Scope,
      will call the converter on every object in the list.
      ###
      @lookup= (id,callback,onErr)=>
        opts = (filter:@options.searchFilter(id),scope:'sub')
        console.log opts
        @client.search(@options.searchBase,opts,(err,res)=>
          assert.ifError err
          list =[]
          res.on 'searchEntry', (entry)=>
            # We shall only get one user so push him to call back
            list.push @options.converter entry.object
          res.on 'searchReference',(referral)=>
            console.log "referral: #{referral.uris.join()}"
          res.on 'err', (err)->
            console.log "error: #{err.message}"
            onErr(err)
          res.on 'end', (result)->
            callback(list)
          )
      ###
        Returns all result as LDAP(attributes)-object without calling the converter.
        NOTE: Do not use this as standard function, only for sensitive or password modifying usage.
      ###
      @lookupLDAP= (id,callback,onErr)=>
        opts = (filter:@options.searchFilter(id),scope:'sub')
        console.log opts
        @client.search(@options.searchBase,opts,(err,res)=>
          assert.ifError err
          list =[]
          res.on 'searchEntry', (entry)=>
            list.push entry.object
          res.on 'searchReference',(referral)=>
            console.log "referral: #{referral.uris.join()}"
          res.on 'err', (err)->
            console.log "error: #{err.message}"
            onErr(err)
          res.on 'end', (result)->
            callback(list)
          )
      ###
      @UserModell is an object which has following members (for a posixAccount)
        cn:"Erika Mustermann"
        "objectClass":["account","posixAccount","top"]
        password:"dadaw"
        uidNumber
        gidNumber(commonly uidNumber):
      Optional:
        userPassword:"emustermann@example.org
      ###
      @addUser=(dnname,UserModell,onSuccess,onError)=>
        # TODO: Konvertierung durch führen
        #(name, entry, controls, callback)
        UserInLdapFormat = UserModell
        console.log UserInLdapFormat
        console.log("Did you see something?")
        @client.add(dnname,UserInLdapFormat,[],(data)=>
          #Callbackrufen
          onSuccess true,data
          )
        ###
        Adds a POSIX user with the supplied attributes
        mail is optional
        Password will be stored **uncrypted**, please use package ssha
        for securing your passwords.
        ###
      @addPosixUser=(dnnameinclusername,cn,username,uidNumber,gidNumber,password,homeDirectory,callback,mail)=>
        customer=
          objectClass:["account","posixAccount","top"]
          cn:cn
          uidNumber:uidNumber
          gidNumber:gidNumber
          userPassword:password
          uid:username
          homeDirectory:homeDirectory
        if mail?
          # Extensible machen..
          customer.objectClass.unshift "extensibleObject"
          customer.mail = mail
        console.log customer
        @client.add dnnameinclusername,customer,
        [],callback || (data)->console.log("not implemented")
      @destroy = ()=>
        @client.unbind()
      ###
      This function changes/overrides (preexisting) attributes of an Object.
      userdn is a dn for a account
      changes is a object, like
      cn:"Test User"
      ###
      @modifyUser=(userdn,changes,callback)=>
        changeobj = new ldap.Change(
          operation:"replace"
          modification:changes
        )
        #y(name, change, controls, callback)
        @client.modify(userdn,changeobj,[],callback)
        ###
        This function is a wrapper function that uses modifyUser
        callback is called with undefined, when it was successfull
        ###
      @changePassword=(userdn,newpassword,callback)=>
        pwchange=
          userPassword:newpassword
        @modifyUser(userdn,pwchange,callback)
  new LDAPLookup opts
