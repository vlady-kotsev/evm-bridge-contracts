// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {IWrappedToken, IERC20} from "../interfaces/IWrappedToken.sol";
import {SignatureChecker} from "../utils/SignatureChecker.sol";
import {ITokenManager} from "../interfaces/ITokenManager.sol";
import {IDiamond} from "../interfaces/IDiamond.sol";
import {LibTokenManager} from "../libs/LibTokenManager.sol";
import {SafeERC20} from "@openzeppelincontracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {TokenManagerErrors} from "./errors/TokenManagerErrors.sol";

contract TokenManagerFacet is SignatureChecker, ITokenManager, TokenManagerErrors {
    using SafeERC20 for IERC20;
    using SafeERC20 for IWrappedToken;

    event TokensLocked(address indexed user, address indexed tokenAddress, uint256 amount);
    event WrappedTokensMinted(address indexed to, address indexed wrappedTokenAddress, uint256 amount);
    event WrappedTokensBurned(address indexed user, address indexed tokenAddress, uint256 amount);
    event TokensUnlocked(address indexed user, address indexed tokenAddress, uint256 amount);
    event MinBridgeableAmountUpdated(uint256 amount);
    event TreasuryAddressUpdated();
    event TokenFundsWithdrawnToTreasury(address);

    function initTokenManager(uint248 minBridgeableAmount, address treasuryAddress) external {
        LibTokenManager.Storage storage tms = LibTokenManager.getTokenManagerStorage();
        if (tms.initialized) {
            revert TokenManager__FacetAlreadyInitialized();
        }
        if (minBridgeableAmount == 0) {
            revert TokenManager__InvalidMinBridgeableAmount();
        }
        if (treasuryAddress == address(0)) {
            revert TokenManager__InvalidTreasuryAddress();
        }

        tms.initialized = true;
        tms.minBridgeableAmount = minBridgeableAmount;
        tms.treasuryAddress = treasuryAddress;
    }

    function lockTokens(uint256 amount, address tokenAddress)
        external
        enforceSupportedToken(tokenAddress)
        enforceAboveMinBridgeableAmount(amount)
    {
        IERC20 token = IERC20(tokenAddress);
        token.safeTransferFrom(msg.sender, address(this), amount);

        uint256 calculatedAfterFee = amount - IDiamond(address(this)).calculateFee(amount);

        emit TokensLocked(msg.sender, tokenAddress, calculatedAfterFee);
    }

    function mintWrappedTokens(
        uint256 amount,
        address to,
        address wrappedTokenAddress,
        bytes memory message,
        bytes[] memory signatures
    ) external enforceIsSignedByAllMembers(message, signatures) enforceSupportedToken(wrappedTokenAddress) {
        if (to == address(0)) {
            revert TokenManager__InvalidMintReceiverAddress();
        }
        if (amount == 0) {
            revert TokenManager__InvalidMintAmount();
        }
        IWrappedToken token = IWrappedToken(wrappedTokenAddress);
        token.mint(to, amount);

        emit WrappedTokensMinted(to, wrappedTokenAddress, amount);
    }

    function burnWrappedToken(uint256 amount, address wrappedTokenAddress)
        external
        enforceSupportedToken(wrappedTokenAddress)
        enforceAboveMinBridgeableAmount(amount)
    {
        IWrappedToken token = IWrappedToken(wrappedTokenAddress);
        token.burnFrom(msg.sender, amount);

        emit WrappedTokensBurned(msg.sender, wrappedTokenAddress, amount);
    }

    function unlockTokens(
        uint256 amount,
        address to,
        address tokenAddress,
        bytes memory message,
        bytes[] memory signatures
    ) external enforceIsSignedByAllMembers(message, signatures) enforceSupportedToken(tokenAddress) {
        if (amount == 0) {
            revert TokenManager__InvalidUnlockAmount();
        }
        if (to == address(0)) {
            revert TokenManager__InvalidUnlockReceiverAddress();
        }

        uint256 calculatedAfterFee = amount - IDiamond(address(this)).calculateFee(amount);

        IERC20 token = IERC20(tokenAddress);
        token.safeTransfer(to, calculatedAfterFee);

        emit TokensUnlocked(to, tokenAddress, calculatedAfterFee);
    }

    function getMinimumBridgeableAmount() external view returns (uint256) {
        LibTokenManager.Storage storage tms = LibTokenManager.getTokenManagerStorage();
        return tms.minBridgeableAmount;
    }

    function setMinimumBridgeableAmount(uint248 amount, bytes memory message, bytes[] memory signatures)
        external
        enforceIsSignedByAllMembers(message, signatures)
    {
        if (amount == 0) {
            revert TokenManager__InvalidMinBridgeableAmount();
        }
        LibTokenManager.Storage storage tms = LibTokenManager.getTokenManagerStorage();
        tms.minBridgeableAmount = amount;

        emit MinBridgeableAmountUpdated(amount);
    }

    function addNewSupportedToken(address tokenAddress, bytes memory message, bytes[] memory signatures)
        external
        enforceIsSignedByAllMembers(message, signatures)
    {
        LibTokenManager.Storage storage tms = LibTokenManager.getTokenManagerStorage();

        if (tms.supportedTokens[tokenAddress]) {
            revert TokenManager__TokenAlreadyAdded();
        }
        tms.supportedTokens[tokenAddress] = true;
    }

    function setTreasuryAddress(address treasuryAddress, bytes memory message, bytes[] memory signatures)
        external
        enforceIsSignedByAllMembers(message, signatures)
    {
        if (treasuryAddress == address(0)) {
            revert TokenManager__InvalidTreasuryAddress();
        }
        LibTokenManager.Storage storage tms = LibTokenManager.getTokenManagerStorage();
        tms.treasuryAddress = treasuryAddress;
        emit TreasuryAddressUpdated();
    }

    function withdrawTokenFunds(address tokenAddress) external enforceSupportedToken(tokenAddress) {
        LibTokenManager.Storage storage tms = LibTokenManager.getTokenManagerStorage();
        IWrappedToken token = IWrappedToken(tokenAddress);
        uint256 acumulatedBalance = token.balanceOf(address(this));
        token.safeTransfer(tms.treasuryAddress, acumulatedBalance);
        emit TokenFundsWithdrawnToTreasury(tokenAddress);
    }

    function isTokenSupported(address tokenAddress) external view returns (bool) {
        LibTokenManager.Storage storage tms = LibTokenManager.getTokenManagerStorage();
        return tms.supportedTokens[tokenAddress];
    }

    function getTreasuryAddress(bytes memory message, bytes[] memory signatures)
        external
        enforceIsSignedByAllMembers(message, signatures)
        returns (address)
    {
        LibTokenManager.Storage storage tms = LibTokenManager.getTokenManagerStorage();
        return tms.treasuryAddress;
    }

    modifier enforceSupportedToken(address tokenAddress) {
        LibTokenManager.Storage storage tms = LibTokenManager.getTokenManagerStorage();
        if (!tms.supportedTokens[tokenAddress]) {
            revert TokenManager__TokenNotSupported(tokenAddress);
        }
        _;
    }

    modifier enforceAboveMinBridgeableAmount(uint256 amount) {
        LibTokenManager.Storage storage tms = LibTokenManager.getTokenManagerStorage();
        if (amount < tms.minBridgeableAmount) {
            revert TokenManager__InvalidTransferAmount(amount);
        }
        _;
    }
}
