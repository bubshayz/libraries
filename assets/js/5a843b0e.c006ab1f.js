"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[9186],{66827:function(e){e.exports=JSON.parse('{"functions":[{"name":"new","desc":"","params":[{"name":"remoteEvent","desc":"","lua_type":"RemoteEvent"}],"returns":[{"desc":"","lua_type":"ClientRemoteSignal\\r\\n"}],"function_type":"static","private":true,"source":{"line":26,"path":"src/Network/Client/ClientRemoteSignal.lua"}},{"name":"IsA","desc":"Returns a boolean indicating if `self` is a client remote signal or not.","params":[{"name":"self","desc":"","lua_type":"any"}],"returns":[{"desc":"","lua_type":"boolean\\r\\n"}],"function_type":"static","source":{"line":41,"path":"src/Network/Client/ClientRemoteSignal.lua"}},{"name":"Connect","desc":"Connects `callback` to the client remote signal so that it is called whenever the serverside remote signal\\n(to which the client remote signal is connected to) dispatches some data to the client remote signal. The\\nconnected callback is called with the data dispatched to the client remote signal.","params":[{"name":"callback","desc":"","lua_type":"(...any) -> any"}],"returns":[{"desc":"","lua_type":"SignalConnection"}],"function_type":"method","tags":["ClientRemoteSignal instance"],"source":{"line":54,"path":"src/Network/Client/ClientRemoteSignal.lua"}},{"name":"ConnectOnce","desc":"Works almost exactly the same as [ClientRemoteSignal:Connect], except the connection returned is \\ndisconnected immediately upon `callback` being called.","params":[{"name":"callback","desc":"","lua_type":"(...any) -> any"}],"returns":[{"desc":"","lua_type":"SignalConnection"}],"function_type":"method","tags":["ClientRemoteSignal instance"],"source":{"line":66,"path":"src/Network/Client/ClientRemoteSignal.lua"}},{"name":"DisconnectAll","desc":"Disconnects all connections connected via [ClientRemoteSignal:Connect] or [ClientRemoteSignal:ConnectOnce].","params":[],"returns":[],"function_type":"method","tags":["ClientRemoteSignal instance"],"source":{"line":76,"path":"src/Network/Client/ClientRemoteSignal.lua"}},{"name":"Fire","desc":"Fires `...` arguments to the serverside remote signal (to which the client remote signal is connected to).","params":[{"name":"...","desc":"","lua_type":"any"}],"returns":[],"function_type":"method","tags":["ClientRemoteSignal instance"],"source":{"line":86,"path":"src/Network/Client/ClientRemoteSignal.lua"}},{"name":"Wait","desc":"Yields the thread until the serverside remote signal (to which the client remote signal is connected to) dispatches\\nsome data to the client remote signal.","params":[],"returns":[],"function_type":"method","tags":["ClientRemoteSignal instance","yields"],"source":{"line":98,"path":"src/Network/Client/ClientRemoteSignal.lua"}},{"name":"Destroy","desc":"Destroys the client remote signal and renders it unusable.","params":[],"returns":[],"function_type":"method","tags":["ClientRemoteSignal instance"],"source":{"line":108,"path":"src/Network/Client/ClientRemoteSignal.lua"}}],"properties":[],"types":[{"name":"SignalConnection","desc":"","fields":[{"name":"Disconnect","lua_type":"() -> ()","desc":""},{"name":"Connected","lua_type":"boolean","desc":""}],"source":{"line":15,"path":"src/Network/Client/ClientRemoteSignal.lua"}}],"name":"ClientRemoteSignal","desc":"The clientside counterpart of [RemoteSignal]. A client remote signal in layman\'s terms is just an object \\nconnected to a serverside remote signal.","source":{"line":7,"path":"src/Network/Client/ClientRemoteSignal.lua"}}')}}]);