// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32, euint8 } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

/**
 * @title PrivacyBuildingCertification
 * @notice Privacy-preserving building certification system using Zama FHE
 * @dev Uses Fully Homomorphic Encryption for confidential energy and efficiency data
 */
contract PrivacyBuildingCertification is SepoliaConfig {
    address public owner;
    address public authority;
    uint256 public totalBuildings;

    struct BuildingData {
        euint32 energy;
        euint8 efficiency;
        bool hasData;
    }

    mapping(uint256 => BuildingData) private buildings;
    mapping(uint256 => address) public buildingOwner;
    mapping(uint256 => bool) public verified;
    mapping(uint256 => uint256) public score;

    event BuildingSubmitted(uint256 indexed id, address indexed owner);
    event BuildingVerified(uint256 indexed id);
    event ScoreCalculated(uint256 indexed id, uint256 score);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAuthority() {
        require(msg.sender == authority, "Not authorized");
        _;
    }

    constructor(address _authority) {
        owner = msg.sender;
        authority = _authority;
    }

    /**
     * @notice Submit building data with encrypted energy consumption and efficiency
     * @param _energy Energy consumption value (will be encrypted)
     * @param _efficiency Efficiency rating 0-100 (will be encrypted)
     */
    function submitBuilding(uint32 _energy, uint8 _efficiency) external {
        totalBuildings++;
        uint256 id = totalBuildings;

        // Encrypt the values
        euint32 encryptedEnergy = FHE.asEuint32(_energy);
        euint8 encryptedEfficiency = FHE.asEuint8(_efficiency);

        buildings[id] = BuildingData({
            energy: encryptedEnergy,
            efficiency: encryptedEfficiency,
            hasData: true
        });

        buildingOwner[id] = msg.sender;

        // Grant access permissions
        FHE.allowThis(encryptedEnergy);
        FHE.allowThis(encryptedEfficiency);
        FHE.allow(encryptedEnergy, msg.sender);
        FHE.allow(encryptedEfficiency, msg.sender);

        emit BuildingSubmitted(id, msg.sender);
    }

    /**
     * @notice Verify a building (only authority can do this)
     * @param id Building ID to verify
     */
    function verifyBuilding(uint256 id) external onlyAuthority {
        require(id > 0 && id <= totalBuildings, "Invalid building ID");
        require(buildings[id].hasData, "Building not found");

        verified[id] = true;
        emit BuildingVerified(id);
    }

    /**
     * @notice Calculate the certification score for a building
     * @param id Building ID
     * @dev Triggers async decryption request
     */
    function calculateScore(uint256 id) external {
        require(id > 0 && id <= totalBuildings, "Invalid building ID");
        require(buildings[id].hasData, "Building not found");
        require(verified[id], "Not verified");
        require(
            buildingOwner[id] == msg.sender || msg.sender == authority,
            "Not authorized"
        );

        // Calculate score using FHE operations: (efficiency * 10)
        // Note: Division is not supported in FHE, so we simplify the calculation
        euint32 totalScore = FHE.mul(
            FHE.asEuint32(buildings[id].efficiency),
            FHE.asEuint32(10)
        );

        // Request async decryption
        bytes32[] memory cts = new bytes32[](1);
        cts[0] = FHE.toBytes32(totalScore);
        FHE.requestDecryption(cts, this.processScore.selector);
    }

    /**
     * @notice Callback function for decryption result
     * @param requestId Decryption request ID
     * @param _score Decrypted score value
     * @param signatures KMS signatures for verification
     */
    function processScore(
        uint256 requestId,
        uint32 _score,
        bytes[] memory signatures
    ) external {
        // Verify KMS signatures
        FHE.checkSignatures(requestId, signatures);

        // Store the decrypted score for the last building
        score[totalBuildings] = uint256(_score);
        emit ScoreCalculated(totalBuildings, uint256(_score));
    }

    /**
     * @notice Get the score for a building
     * @param id Building ID
     * @return The certification score (0 if not calculated yet)
     */
    function getScore(uint256 id) external view returns (uint256) {
        require(id > 0 && id <= totalBuildings, "Invalid building ID");
        return score[id];
    }

    /**
     * @notice Change the certification authority
     * @param newAuthority New authority address
     */
    function changeAuthority(address newAuthority) external onlyOwner {
        require(newAuthority != address(0), "Invalid address");
        authority = newAuthority;
    }

    /**
     * @notice Check if a building exists
     * @param id Building ID
     * @return True if building exists
     */
    function buildingExists(uint256 id) external view returns (bool) {
        return id > 0 && id <= totalBuildings && buildings[id].hasData;
    }
}