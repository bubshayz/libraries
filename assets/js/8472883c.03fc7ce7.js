"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[9695],{17461:function(e){e.exports=JSON.parse('{"functions":[{"name":"new","desc":"Creates and returns a new remote signal.","params":[],"returns":[{"desc":"","lua_type":"RemoteSignal"}],"function_type":"static","source":{"line":36,"path":"src/Network/Server/RemoteSignal.lua"}},{"name":"IsA","desc":"Returns a boolean indicating if `self` is a remote signal or not.","params":[{"name":"self","desc":"","lua_type":"any"}],"returns":[{"desc":"","lua_type":"boolean\\r\\n"}],"function_type":"static","source":{"line":50,"path":"src/Network/Server/RemoteSignal.lua"}},{"name":"ConnectOnce","desc":"Works almost exactly the same as [RemoteSignal:ConnectOnce], except the connection returned \\nis disconnected automaticaly once `callback` is called.","params":[{"name":"callback","desc":"","lua_type":"(...any) -> ()"}],"returns":[{"desc":"","lua_type":"SignalConnection"}],"function_type":"method","tags":["RemoteSignal instance"],"source":{"line":62,"path":"src/Network/Server/RemoteSignal.lua"}},{"name":"Connect","desc":"Connects `callback` to the remote signal so that it is called whenever the client\\nfires the remote signal, and `callback` will be passed arguments sent by the client.","params":[{"name":"callback","desc":"","lua_type":"(...any) -> ()"}],"returns":[{"desc":"","lua_type":"SignalConnection"}],"function_type":"method","tags":["RemoteSignal instance"],"source":{"line":74,"path":"src/Network/Server/RemoteSignal.lua"}},{"name":"FireForSpecificPlayers","desc":"Fires the arguments `...` to every player in the `players` table only.","params":[{"name":"players","desc":"","lua_type":"{ Player }"},{"name":"...","desc":"","lua_type":"any"}],"returns":[],"function_type":"method","tags":["RemoteSignal instance"],"source":{"line":84,"path":"src/Network/Server/RemoteSignal.lua"}},{"name":"FireForPlayer","desc":"Fires the arguments `...` to  `player`.","params":[{"name":"player","desc":"","lua_type":"Player"},{"name":"...","desc":"","lua_type":"any"}],"returns":[],"function_type":"method","tags":["RemoteSignal instance"],"source":{"line":96,"path":"src/Network/Server/RemoteSignal.lua"}},{"name":"FireForAll","desc":"Fires the arguments `...` to every player in the game.","params":[{"name":"...","desc":"","lua_type":"any"}],"returns":[],"function_type":"method","tags":["RemoteSignal instance"],"source":{"line":106,"path":"src/Network/Server/RemoteSignal.lua"}},{"name":"DisconnectAll","desc":"Disconnects all connections connected via [RemoteSignal:Connect] or [RemoteSignal:ConnectOnce].","params":[],"returns":[],"function_type":"method","tags":["RemoteSignal instance"],"source":{"line":116,"path":"src/Network/Server/RemoteSignal.lua"}},{"name":"Destroy","desc":"Destroys the remote signal and renders it unusable.","params":[],"returns":[],"function_type":"method","tags":["RemoteSignal instance"],"source":{"line":126,"path":"src/Network/Server/RemoteSignal.lua"}},{"name":"Dispatch","desc":"","params":[{"name":"name","desc":"","lua_type":"string"},{"name":"parent","desc":"","lua_type":"Instance"}],"returns":[],"function_type":"method","private":true,"source":{"line":134,"path":"src/Network/Server/RemoteSignal.lua"}}],"properties":[],"types":[{"name":"SignalConnection","desc":"","fields":[{"name":"Disconnect","lua_type":"() -> ()","desc":""},{"name":"Connected","lua_type":"boolean","desc":""}],"source":{"line":21,"path":"src/Network/Server/RemoteSignal.lua"}}],"name":"RemoteSignal","desc":"A remote signal in layman\'s terms is simply an object which dispatches data\\nto a client (who can listen to this data through a client remote signal) and \\nlistens to data dispatched to it self by a client (through a client remote signal).\\n\\n:::note\\n[Argument limitations](https://create.roblox.com/docs/scripting/events/argument-limitations-for-bindables-and-remotes)\\ndo apply since remote events are internally used by remote signals to dispatch data to clients.\\n:::","source":{"line":13,"path":"src/Network/Server/RemoteSignal.lua"}}')}}]);