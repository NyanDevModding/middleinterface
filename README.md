# middleinterface
middleclass's add-on for interface system

this lua module is used for OOP lua with the middleclass module that you can find here : https://github.com/kikito/middleclass

## How to use middleinterface

### Interface creation

to create an interface, you will do just like you would in middleclass, only the 'class' keyword turn into 'interface'

```lua
local interface = require 'middleinterface'

local ISpeakable = interface("ISpeakable")

function ISpeakable:speak() end

return ISpeakable
```
here, the ISpeakable interface has one 'mustOverrideMethod' : draw(). you will need to override it while instanciating the interface or implementing it.

two other function are possible :
the 'cantOverrideMethod' for a function that will stay the same all the time and the 'overridableMethod', a method that can be overriden or not
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
