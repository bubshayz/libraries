## 2022-07-08

### Added

- Added `RemoteSignal:wait`.

### Changed

- Removed `RemoteSignal:disonnectAll` and `ClientRemoteSignal:disonnectAll`.
- Removed `RemoteSignal:connectOnce` and `ClientRemoteSignal:connectOnce`.
- Fix bug with `ClientRemoteSignal:connect` and `ClientRemoteSignal:wait` not receiving the dispatched events properly in some edge cases.
- `RemoteSignal:connect` and `ClientRemoteSignal:connect` now return an `RBXScriptConnectionObject`. 
- Internal code refactor and improvements.
- Documentation improvements.

## 2022-07-07

### Added

- Added `RemoteSignal:fireAllClientsExcept`.

### Changed

- Change `RemoteSignal:fireForClients` to `RemoteSignal:fireClients`.
- Internal code refactor for `network`.
- Documentation improvements for `network`.

## 2022-07-03

### Added

- Added `numberUtil.formatToHMS`.
- Added `numberUtil.formatToMS`.

### Changed

- Improve error checking within `windLines` module.
- Improve documentation.
- Rename `numberUtil.format` to `numberUtil.suffix`.

## 2022-07-02

### Changed

- Fix middleware related bugs within the `network` module.
- Improve method names within `RemoteProperty`.

## 2022-07-01

### Changed

- Rework all libraries to follow the Roblox lua style guide.
- Implement middleware support for remote properties and remote signals.
- Improve documentation of all libraries.