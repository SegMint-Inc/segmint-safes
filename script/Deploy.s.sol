// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../test/Base.sol";

contract DeployScript is Base {
    using stdJson for string;

    uint256 public deployerPrivateKey;
    address public deployer;
    address public admin;

    function setUp() public {
        deployerPrivateKey = vm.envUint("DEPLOYER_PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);

        string memory root = vm.projectRoot();
        string memory basePath = string.concat(root, "/script/constants/");
        string memory path = string.concat(basePath, vm.envString("CONSTANTS_FILENAME"));
        string memory jsonConstants = vm.readFile(path);

        admin = abi.decode(vm.parseJson(jsonConstants, ".admin"), (address));
    }

    function run() public {
        vm.startBroadcast(deployer);
        coreSetup({ admin: admin });
        vm.stopBroadcast();
    }
}
