"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[74],{82957:e=>{e.exports=JSON.parse('{"functions":[],"properties":[{"name":"Server","desc":" ","lua_type":"NetworkServer","readonly":true,"source":{"line":29,"path":"src/network/init.lua"}},{"name":"client","desc":" ","lua_type":"networkClient","readonly":true,"source":{"line":35,"path":"src/network/init.lua"}}],"types":[],"name":"network","desc":"A simple yet incredibly useful network module which simplifies and extends server-client communication.\\n\\n```lua\\nlocal Workspace = game:GetService(\\"Workspace\\")\\n\\n-- Server\\nlocal testNetwork = Network.Server.new(\\"TestNetwork\\")\\ntestNetwork:append(\\"method\\", function(player)\\n\\treturn (\\"hi, %s!\\"):format(player.Name)\\nend)\\ntestNetwork:dispatch(Workspace)\\n\\n-- Client\\nlocal Workspace = game:GetService(\\"Workspace\\")\\n\\nlocal testNetwork = network.client.fromParent(\\"TestNetwork\\", Workspace):expect()\\nprint(testNetwork.method()) --\x3e \\"hi, bubshayz!\\"\\n```","source":{"line":23,"path":"src/network/init.lua"}}')}}]);