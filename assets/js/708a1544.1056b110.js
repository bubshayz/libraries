"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[5974],{52253:t=>{t.exports=JSON.parse('{"functions":[{"name":"getMatchingRowsValue","desc":"Searches `matrix` row wise, and returns a value in a row which matches with\\nthe rest of the values of that row. E.g:\\n\\n```lua\\nlocal matrix = {\\n\\t{1, 1, 1},\\n\\t{5, 5, 2}, \\n\\t{0, 0, 2},\\n}\\n\\nprint(matrixUtil.getMatchingRowsValue(matrix)) --\x3e 1 (The first row is equally matched (all 1s))\\n```\\n\\nAdditionally, you can specify `depth` if you want to control how far the \\nmethod should check each row. For e.g: \\n\\n```lua\\nlocal matrix = {\\n\\t{1, 2, 3, 4}, \\n\\t{5, 6, 7, 8}, \\n\\t{1, 1, 1, 0}, \\n}\\n\\nprint(matrixUtil.getMatchingRowsValue(matrix, 3)) --\x3e 1  (The last row\'s first 3 values (1s) are equally matched)\\nprint(matrixUtil.getMatchingRowsValue(matrix, 4)) --\x3e nil  (No row\'s first 4 values are equally matched)\\n```","params":[{"name":"matrix","desc":"","lua_type":"{ { any } }"},{"name":"depth","desc":"","lua_type":"number?"}],"returns":[{"desc":"","lua_type":"any\\r\\n"}],"function_type":"static","source":{"line":46,"path":"src/matrixUtil/init.lua"}},{"name":"getMatchingDiagonalColumnsValue","desc":"Searches `matrix` diagonally, and returns a value which matches with the \\nrest of the values of the arrays in `matrix`. \\n\\nE.g:\\n\\n```lua\\nlocal matrix = {\\n\\t{5, 0, 0},\\n\\t{0, 5, 0},\\n\\t{0, 0, 5},\\n}\\n\\nprint(matrixUtil.getMatchingDiagonalColumnsValue(matrix)) --\x3e 1 (A column has matching values diagonally (just 5s))\\n```\\n\\nAdditionally, you can specify `depth` if you want to control how far the \\nmethod should search `matrix` diagonally. For e.g: \\n\\n```lua\\nlocal matrix = {\\n\\t{2, 0, 0, 0},\\n\\t{0, 2, 0, 0},\\n\\t{0, 0, 2, 0},\\n\\t{0, 0, 0, 0},\\n}\\n\\nprint(matrix.getMatchingDiagonalColumnsValue(matrix, 3)) --\x3e 2 (A column has FIRST 3 matching values diagonally (just 2s))\\n```","params":[{"name":"matrix","desc":"","lua_type":"{ { any } }"},{"name":"depth","desc":"","lua_type":"number?"}],"returns":[{"desc":"","lua_type":"any\\r\\n"}],"function_type":"static","source":{"line":100,"path":"src/matrixUtil/init.lua"}},{"name":"getMatchingColumnsValue","desc":"Searches `matrix` column wise and returns a value of a column which matches \\nwith the rest of the values of that column. E.g:\\n\\n```lua\\nlocal matrix = {\\n\\t{5, 0, 0},\\n\\t{5, 1, 0},\\n\\t{5, 0, 1},\\n}\\n\\nprint(matrixUtil.getMatchingColumnsValue(matrix)) --\x3e 5 (A column has ALL equally matching values (just 5s))\\n```\\n\\nAdditionally, you can specify `depth` if you want to control how far the \\nmethod should check each column. For e.g: \\n\\n```lua\\nlocal matrix = {\\n\\t{5, 0, 0},\\n\\t{5, 0, 0},\\n\\t{2, 1, 1},\\n}\\n\\nprint(matrixUtil.getMatchingColumnsValue(matrix, 2)) --\x3e 5 (A column has FIRST 2 matching values (just 5s))\\n```","params":[{"name":"matrix","desc":"","lua_type":"{ { any } }"},{"name":"depth","desc":"","lua_type":"number?"}],"returns":[{"desc":"","lua_type":"any\\r\\n"}],"function_type":"static","source":{"line":167,"path":"src/matrixUtil/init.lua"}}],"properties":[],"types":[],"name":"matrixUtil","desc":"A utility module for working with matrixes. A matrix is simply an array \\nconsisting of arrays, e.g:\\n\\n```lua\\nlocal matrix = {\\n\\t{1, 1, 2},\\n\\t{1, 1, 1},\\n\\t{3, 3, 3},\\n}\\n```","source":{"line":15,"path":"src/matrixUtil/init.lua"}}')}}]);