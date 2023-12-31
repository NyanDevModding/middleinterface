# middleinterface
middleclass's add-on for interface system

this lua module is used for OOP lua with the middleclass module that you can find here : https://github.com/kikito/middleclass

## Installation of middleinterface

To use middleinterface, you will need the [middleclass](https://github.com/kikito/middleclass) module;
you can then create another module, where you will copy the middleinterface code;
and, to finish, you will have to add the following function to the middleclass's defaultMixin.static :
```lua
implements = function(self, ...)
   for _, interface in ipairs({...}) do
      interface:implementedBy(self)
   end
end,
```
(or line 177 if you prefer)

## How to use middleinterface

### Interface creation

to create an interface, you will do just like you would in middleclass, only the 'class' keyword turn into 'interface'

```lua
local interface = require 'middleinterface'

local ISpeakable = interface("ISpeakable")

function ISpeakable:speak() end

return ISpeakable
```
here, the **ISpeakable interface** has one *mustOverrideMethod*:speak(). you will need to override it while instantiating the interface or implementing it.

two other function are possible :
the *cantOverrideMethod* for a function that will stay the same all the time and the *overridableMethod*, a method that can be overriden or not
we define them like this :

```lua
local interface = require 'middleinterface'

local ISpeakable = interface("ISpeakable")

function ISpeakable:speak() end

ISpeakable:_cantOverrideFunction("finalSpeak", function(self)
   print "speaking from final speak"
end)

ISpeakable:_overridableFunction("overridableSpeak", function(self)
   print "speaking from a function that may be overriden"
end)


return ISpeakable
```

### Using the interface

Now that you have your interface, you can use it by two ways : instantiating and implementing

#### instantiating

if you need a basic instance of an interface to store some function overrides then you'll have to instatiate this interface :
```lua
local ISpeakableInstance = ISpeakable:new({
   speak = function(self)
      print("speaking from an instance of ISpeakable")
   end
})
```
yep, you'll need do rewrite *every* overrides in this argument table 🗿, sorry about that, one day we'll have a program that will generate for us the skeleton of this table... 
Anyway,
you'll need to override every mustOverride functions and then you will gain access to all of these functions in your interface instance + the final functions and overridable

#### implementing

here comes the OOP programming, if you need a contract for a class that makes her override some methods + giving her access to some other (thats what an interface is) then you will need to implement an interface

```lua
local class = require 'middleclass'

local ISpeakable = require 'ISpeakable'

Person = class('Person')

function Person:initialize(name)
  self.name = name
end

function Person:speak()
  print('Hi, I am ' .. self.name ..'.')
end

Person:implements(ISpeakable)

return module
```
(one day we're gonna also have a programm for generating the skeleton of the methods overrides)

seems useless uh ?
but if you delete the Person:speak() then it will print you an error like "oh seems like you forget to respect the contract : the speak method is absent and must be overriden..."

⚠ please write your *:implements* at the end of your class, thats important

Maybe, some day, gonna do a bigger tutorial in wiki github page
