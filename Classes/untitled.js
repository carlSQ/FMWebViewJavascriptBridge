var global = this;

(function() {

    var modules = {};
 
    function Module (path) {
      return {
          path: path,
          load: nativeLoadJSModule,
          exports: {},
          loaded: false
      }
    }

    function require(path) {
        var cacheModule = modules[path];
        if (cacheModule) {
            return cacheModule.exports;
        }

        return requireImpl(path);
    }

    function requireImpl(path) {

        var module = Module(path);
        modules[path] = module;
        try {

            module.load.call(global,global,require, module, module.exports, path);
            module.loaded = true;

         } catch(e) {
            module.loaded = false;
            delete modules[path];
        }

        return module.exports;
    }

    global.require = require;
  })();