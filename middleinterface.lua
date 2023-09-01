local middleinterface = {
   _VERSION     = '1.0.0.0',
   _DESCRIPTION = "middleclass's add-on for interface system",
   _URL         = '',
   _LICENSE     = "MIT LICENSE"
}

local _overridablePrefix = "overridable_"
local _mustOverridePrefix = "mustOverride_"
local _cantOverridePrefix = "cantOverride_"

local function _includeMixin(interface, mixin)
   assert(type(mixin) == 'table', "mixin must be a table")
   
   for name,method in pairs(mixin) do
      if name ~= "included" and name ~= "static" then interface[name] = method end
   end

   for name,method in pairs(mixin.static or {}) do
      mixin[name] = method
   end

   if type(mixin.included)=="function" then mixin:included(interface) end
   return interface
end

local function _includeDefaultMixin(interface, mixin)
   for name,method in pairs(mixin) do
      if name ~= "included" and name ~= "static" then rawset(interface, name, method) end
   end

   for name,method in pairs(mixin.static or {}) do
      rawset(interface, name, method)
   end

   if type(mixin.included)=="function" then mixin:included(interface) end
   return interface
end

local function _getMethodPlace(interface, name)
   return interface.__mustOverrideMethods[name] ~= nil and "__mustOverrideMethods" or(interface.____cantOverrideMethods[name] ~= nil and "__cantOverrideMethods" or (interface.__overridableMethods[name] ~= nil and "__overridableMethods" or nil))
end


local function _isOverridable(interface, name)
   return _getMethodPlace(interface, name)  ~= "__cantOverrideMethods" or _getMethodPlace(interface, name) ~= nil
end

local function _declareInterfaceMethod(interface, name, f)
   if name:find(_overridablePrefix) == 1 then
      interface.__overridableMethods[name:sub(#_overridablePrefix + 1, #name)] = f
   elseif name:find(_cantOverridePrefix) == 1 then
      interface.__cantOverrideMethods[name:sub(#_cantOverridePrefix + 1, #name)] = f
   else
      interface.__mustOverrideMethods[name] = f
   end
end

local function _declareInterfaceField(interface, name, v)
   if type(v) == 'function' then
      _declareInterfaceMethod(interface, name, v)
   else
      rawset(interface, name, v)--this value is static and better be final
   end
end

local function _createInterface(name, super)
   local interface = { name = name, super = super,
      __cantOverrideMethods = {}, __overridableMethods = {},
      __mustOverrideMethods = {}, subinterfaces = setmetatable({}, {__mode='k'}),
      implementedByTable = setmetatable({}, {__mode='k'})}
   
   setmetatable(interface, {__index = super, __newindex = _declareInterfaceField})
   
   return interface
end

local function _propagateMethod(interface, aInterface, name, f, tableName)
   if not tableName then
      local place = _getMethodPlace(interface, name)
      if not place then return end
      aInterface[place][name] = f
      return
   end
   
   aInterface[tableName][name] = f
end

local function _scanForOverrideErrors(interface, overrideTable)
   
   for name, _ in pairs(interface.__mustOverrideMethods) do
      if overrideTable[name] == nil then
        error("You forget to override the method : " .. name .. " in the " .. interface.name .. " interface instanciation.") -- case you forget to override some must-override methods
      end
   end
   
   for name, _ in pairs(overrideTable) do
      if interface.__mustOverrideMethods[name] == nil and interface.__overridableMethods[name] == nil then
         if interface.__cantOverrideMethods[name] ~= nil then
            error("You're trying to override a nin-overridable method : " .. name .. " in the " .. interface.name .. " interface instanciation.") --case you try to override an __cantOverrideMethod method
         end
         error("You overrided the non-overridable or non-existant method : " .. name .. " in the " .. interface.name .. " interface instanciation.") --case you missclicked while typing the function name
      end
   end
end

local function _instantiateMethods(interface, instance, overrideTable)
   _scanForOverrideErrors(interface, overrideTable)
   for _, t in pairs({interface.__cantOverrideMethods, interface.__overridableMethods}) do
      for name, method in pairs(t) do
         instance[name] = method
      end
   end
   for name, overrideMethod in pairs(overrideTable) do
      instance[name] = overrideMethod
   end
end

local defaultMixin = {
   _cantOverrideFunction = function(self, name, f)
      self[_cantOverridePrefix .. name] = f
   end,
   
   _overridableFunction  = function(self, name, f)
      self[_overridablePrefix .. name] = f
   end,
   
   _mustOverrideFunction = function(self, name, f) --by default
      self[_mustOverridePrefix .. name] = f or function() end
   end,
   
   allocate = function(self)
      assert(type(self) == 'table', "Make sure that you are using 'Interface:allocate' instead of 'Interface.allocate'")
      return setmetatable({ interface = self }, {__index = self})
   end,
   
   new = function(self, overrideTable)
      assert(type(self) == 'table', "Make sure that you are using 'Interface:new' instead of 'Interface.new'")
      local instance = self:allocate()
      _instantiateMethods(self, instance, overrideTable)
      return instance
   end,
   
   subinterface = function(self, name)
      assert(type(self) == 'table', "Make sure that you are using 'Interface:subinterface' instead of 'Interface.subinterface'")
      assert(type(name) == "string", "You must provide a name(string) for your interface")

      local subinterface = _createInterface(name, self)
      
      for _, tableName in ipairs({"__cantOverrideMethods", "__overridableMethods", "__mustOverrideMethods"}) do
         for methodName, f in pairs(self[tableName]) do
            _propagateMethod(self, subinterface, methodName, f, tableName)
         end
      end

      self.subinterfaces[subinterface] = true
      self:subinterfaced(subinterface)

      return subinterface
   end,

   subinterfaced = function(self, other) end,
   
   isSubinterfaceOf = function(self, other)
      return type(other)      == 'table' and
         type(self.super) == 'table' and
         ( self.super == other or self.super:isSubinterfaceOf(other) )
   end,
   
   instanceof = function(self, other)
         return type(other)  == 'table' and
          type(self.interface)   == 'table' and
         (self.interface == other or self.interface:isSubinterfaceOf(other))
   end,
   
   isImplementedBy = function (self, aClass)
      if aClass == nil then return false end -- prevention in case the aClass.super** is nil, to stop the recursion
      if self.interface == nil then
         return self.implementedByTable[aClass.name]
      else
         return self.interface.implementedByTable[aClass.name] or self:isImplementedBy(aClass.super) -- **here
      end
   end,

   include = function(self, ...)
      assert(type(self) == 'table', "Make sure you that you are using 'Interface:include' instead of 'Interface.include'")
      for _,mixin in ipairs({...}) do _includeMixin(self, mixin) end
      return self
   end,
   
   implementedBy = function(self, aClass)
      if self.interface ~= nil then
         self.interface.implementedByTable[aClass.name] = true
         for name, method in pairs(self) do
            if type(method) == "function" and aClass[name] == nil then
               aClass[name] = method
            end
         end
      else
         self.implementedByTable[aClass.name] = true
         for name, method in pairs(self.__cantOverrideMethods) do
            aClass[name] = method
         end
         
         for name, method in pairs(self.__overridableMethods) do
            if aClass[name] == nil then
               aClass[name] = method
            end
         end
         
         for name, method in pairs(self.__mustOverrideMethods) do
            assert(aClass[name] ~= nil, "You must define the mustOverride method : " .. name .. ", in the interface : " .. self.name .. ", for the class : " .. aClass.name)
         end
      end
   end,
}


function middleinterface.interface(name, super)
   assert(type(name) == 'string', "A name (string) is needed for the new class")
   return super and super:subinterface(name) or _includeDefaultMixin(_createInterface(name), defaultMixin)
end

setmetatable(middleinterface, { __call = function(_, ...) return middleinterface.interface(...) end })

return middleinterface
