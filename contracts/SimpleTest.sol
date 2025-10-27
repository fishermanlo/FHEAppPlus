// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32 } from "@fhevm/solidity/lib/FHE.sol";

contract SimpleTest {
    address public owner;
    euint32 private testValue;

    event TestEvent(string message);

    constructor() {
        owner = msg.sender;
        testValue = FHE.asEuint32(100);
        FHE.allowThis(testValue);
    }

    function test() external {
        emit TestEvent("Simple test successful!");
    }

    function getOwner() external view returns (address) {
        return owner;
    }
}