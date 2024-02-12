// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// Libraries
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

// Contracts
import {Actor} from "../utils/Actor.sol";
import {ProtocolAssertions} from "../base/ProtocolAssertions.t.sol";
import {BaseStorage, VaultSimple, VaultSimpleBorrowable, VaultRegularBorrowable} from "../base/BaseStorage.t.sol";

/// @title BaseHandler
/// @notice Contains common logic for all handlers
/// @dev inherits all suite assertions since per-action assertions are implemented in the handlers
contract BaseHandler is ProtocolAssertions {
    using EnumerableSet for EnumerableSet.AddressSet;

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                       SHARED VARAIBLES                                     //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    // SIMPLE VAULT

    /// @notice Sum of all balances in the vault
    mapping(address => uint256) internal ghost_sumBalances;

    /// @notice Sum of all balances per user in the vault
    mapping(address => mapping(address => uint256)) internal ghost_sumBalancesPerUser;

    /// @notice Sum of all shares balances in the vault
    mapping(address => uint256) internal ghost_sumSharesBalances;

    /// @notice Sum of all shares balances per user in the vault
    mapping(address => mapping(address => uint256)) internal ghost_sumSharesBalancesPerUser;

    // SIMPLE BORROWABLE VAULT

    /// @notice Track of the total amount borrowed per vault
    mapping(address => uint256) internal ghost_totalBorrowed;

    /// @notice Track of the total amount borrowed per user per vault
    mapping(address => mapping(address => uint256)) internal ghost_owedAmountPerUser;

    /// @notice Track the enabled collaterals
    mapping(address => EnumerableSet.AddressSet) internal ghost_accountCollaterals;

    ///////////////////////////////////////////////////////////////////////////////////////////////
    //                                         HELPERS                                           //
    ///////////////////////////////////////////////////////////////////////////////////////////////

    /// @notice Returns a random vault address that supports a specific vault type, this optimises the invariant suite
    function _getRandomSupportedVault(uint256 _i, VaultType _minVaultType) internal view returns (address) {
        require(uint8(_minVaultType) < vaults.length, "BaseHandler: invalid vault type");

        // Randomize the vault selection
        uint256 randomValue = _randomize(_i, "randomVault");

        // Use mod math to get a random vault from the range of vaults that support the specific type
        uint256 range = (vaults.length - 1) - uint256(_minVaultType) + 1;
        return vaults[uint256(_minVaultType) + (randomValue % range)];
    }

    function _getRandomAccountCollateral(uint256 i, address account) internal view returns (address) {
        uint256 randomValue = _randomize(i, "randomAccountCollateral");
        return ghost_accountCollaterals[account].at(randomValue % ghost_accountCollaterals[account].length());
    }

    function _getRandomBaseAsset(uint256 i) internal view returns (address) {
        uint256 randomValue = _randomize(i, "randomBaseAsset");
        return baseAssets[randomValue % baseAssets.length];
    }

    /// @notice Helper function to randomize a uint256 seed with a string salt
    function _randomize(uint256 seed, string memory salt) internal pure returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, salt)));
    }

    /// @notice Helper function to approve an amount of tokens to a spender, a proxy Actor
    function _approve(address token, Actor actor_, address spender, uint256 amount) internal {
        bool success;
        bytes memory returnData;
        (success, returnData) = actor_.proxy(token, abi.encodeWithSelector(0x095ea7b3, spender, amount));
        require(success, string(returnData));
    }
}
