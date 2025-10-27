// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title PrivacyBuildingCertificationMock
 * @notice Mock version for testing on standard EVM networks (Sepolia, etc.)
 * @dev This version simulates FHE encryption without actual cryptographic operations
 */
contract PrivacyBuildingCertificationMock {
    address public owner;
    address public authority;
    uint256 public totalBuildings;

    struct BuildingData {
        uint32 energy;
        uint8 efficiency;
        address buildingOwner;
        bool verified;
        uint256 score;
        uint256 timestamp;
    }

    mapping(uint256 => BuildingData) private buildings;

    event BuildingSubmitted(uint256 indexed id, address owner);
    event BuildingVerified(uint256 id);
    event ScoreCalculated(uint256 id, uint256 score);

    constructor(address _authority) {
        owner = msg.sender;
        authority = _authority;
    }

    function submitBuilding(uint32 _energy, uint8 _efficiency) external {
        totalBuildings++;
        uint256 id = totalBuildings;

        buildings[id] = BuildingData({
            energy: _energy,
            efficiency: _efficiency,
            buildingOwner: msg.sender,
            verified: false,
            score: 0,
            timestamp: block.timestamp
        });

        emit BuildingSubmitted(id, msg.sender);
    }

    function verifyBuilding(uint256 id) external {
        require(msg.sender == authority, "Not authorized");
        require(id > 0 && id <= totalBuildings, "Invalid building ID");

        buildings[id].verified = true;
        emit BuildingVerified(id);
    }

    function calculateScore(uint256 id) external {
        require(id > 0 && id <= totalBuildings, "Invalid building ID");
        require(buildings[id].verified, "Not verified");
        require(
            buildings[id].buildingOwner == msg.sender || msg.sender == authority,
            "Not authorized"
        );

        // Simulate FHE calculation: score = (efficiency * 100) - (energy / 1000)
        uint256 efficiencyScore = uint256(buildings[id].efficiency) * 100;
        uint256 energyPenalty = uint256(buildings[id].energy) / 1000;

        uint256 calculatedScore;
        if (efficiencyScore > energyPenalty) {
            calculatedScore = efficiencyScore - energyPenalty;
        } else {
            calculatedScore = 0;
        }

        buildings[id].score = calculatedScore;
        emit ScoreCalculated(id, calculatedScore);
    }

    function getScore(uint256 id) external view returns (uint256) {
        require(id > 0 && id <= totalBuildings, "Invalid building ID");
        return buildings[id].score;
    }

    function buildingOwner(uint256 id) external view returns (address) {
        require(id > 0 && id <= totalBuildings, "Invalid building ID");
        return buildings[id].buildingOwner;
    }

    function verified(uint256 id) external view returns (bool) {
        require(id > 0 && id <= totalBuildings, "Invalid building ID");
        return buildings[id].verified;
    }

    function score(uint256 id) external view returns (uint256) {
        require(id > 0 && id <= totalBuildings, "Invalid building ID");
        return buildings[id].score;
    }

    function getBuildingInfo(uint256 id) external view returns (
        uint32 energy,
        uint8 efficiency,
        address buildingOwnerAddr,
        bool isVerified,
        uint256 buildingScore,
        uint256 timestamp
    ) {
        require(id > 0 && id <= totalBuildings, "Invalid building ID");
        BuildingData memory building = buildings[id];

        return (
            building.energy,
            building.efficiency,
            building.buildingOwner,
            building.verified,
            building.score,
            building.timestamp
        );
    }

    function changeAuthority(address newAuthority) external {
        require(msg.sender == owner, "Not owner");
        authority = newAuthority;
    }
}