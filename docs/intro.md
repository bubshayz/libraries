---
sidebar_position: 1
---

# Getting Started

My open sourced Roblox modules can be installed via [Wally](https://wally.run/) *only*.

## Wally Setup

Once Wally is installed, run `wally init` on your project directory, and then add the various open sourced modules that you need, 
as wally dependencies. For e.g, the following may be a `wally.toml` file for a project that includes a `NumberUtil` wally package:

```toml
[package]
name = "your_name/your_project_name"
version = "1.0.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"

[dependencies]
InstanceUtil = "bubshayz/instanceutil@1.0.8"
```

Now, to install these dependencies, run `wally install` within your project. Wally will  then create a package folder in your directory with the installed dependencies. Then use [Rojo](https://rojo.space/) to sync in the package folder to Studio.

## Usage Example

Once the above necessary steps are completed, the installed wally dependencies can now be used in code, e.g:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberUtil = require(ReplicatedStorage.Packages.NumberUtil)

print(NumberUtil.Factors(2)) --> {1, 2}
```