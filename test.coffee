###
(c) 2014, Henrik Reinstädtler
This is file demonstrates the use od this package
###
ldapoptions=
  connection:
    url:'ldap://localhost:389'
  adminDn:'cn=admin,dc=example,dc=org'
  adminPassword:'Password'
  searchBase:'ou=Users,dc=example,dc=org'
  converter:(objec)->
    objec
  searchFilter: (id)->
    "(uidNumber=#{id})"
    
ldaplookup = require "./index.js"
tester = ldaplookup ldapoptions
onsuccess = (values)->
  console.log "values: #{values}"
  console.log "Information about the user:",values[0]
onerr = (err)->
  console.log err,"That is what occured"
tester.lookup(10000,onsuccess, onerr)
user = `{"uid":"John","cn":"John Smith","objectClass":["account","posixAccount","top"],
"userPassword":"henrik","uidNumber":1000,"gidNumber":1000}`
tester.addUser("uid=rb,ou=Users,dc=development,dc=informatik",user,(data)->
    console.log "Erfolg"+data
  ,
  (data)->
    console.log "Fehler")"
changes=
  userPassword:"katzenscheise"
tester.modifyUser("uid=user,ou=Users,dc=development,dc=informatik",changes,
(data)->
  console.log data?.message)
