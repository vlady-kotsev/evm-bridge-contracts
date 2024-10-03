// SPDX-License-Identifier: MIT
pragma solidity 0.8.23;

import {ECDSA} from "@openzeppelincontracts/contracts/utils/cryptography/ECDSA.sol";
import {LibGovernance} from "../libs/LibGovernance.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library LibSignatureChecker {
    bytes32 constant STORAGE_SLOT = keccak256("signature.checker.storage");

    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    error LibSignatureChecker__InvalidSignature();
    error LibSignatureChecker__InvalidSignatureLength();
    error LibSignatureChecker__InvalidSignatureS();
    error LibSignatureChecker__InvalidRecoveredAddress();
    error LibSignatureChecker__RecoveredAddressNotMember(address);
    error LibSignatureChecker__InvalidSignaturesCount(uint256);
    error LibSignatureChecker__InvalidSignaturesNotUnique();
    error LibSignatureChecker__InvalidMessageHashAlreadyUsed(); 

    struct Storage {
        EnumerableSet.Bytes32Set uniqueSet;
        mapping(bytes32 =>bool) usedMessageHashes;
    }

    function getSignatureCheckerStorage() internal pure returns (Storage storage scs) {
        bytes32 position = STORAGE_SLOT;
        assembly {
            scs.slot := position
        }
    }

    function checkIsMessageHashAlreadyUsed (bytes32 messageHash) internal {
        Storage storage scs = getSignatureCheckerStorage();
        if(scs.usedMessageHashes[messageHash]){
            revert LibSignatureChecker__InvalidMessageHashAlreadyUsed();
        }
        scs.usedMessageHashes[messageHash] = true;
    }

    function checkIsSignedByMember(bytes32 messageHash, bytes memory signature) internal view {
        (address recoveredAddress, ECDSA.RecoverError recoverError,) = messageHash.tryRecover(signature);
        if (recoverError != ECDSA.RecoverError.NoError) {
            bytes4 invalidSignatureSelector = LibSignatureChecker__InvalidSignature.selector;
            bytes4 invalidSignatureLengthSelector = LibSignatureChecker__InvalidSignatureLength.selector;
            bytes4 invalidSignatureSSelector = LibSignatureChecker__InvalidSignatureS.selector;

            assembly {
                switch recoverError
                case 1 { mstore(0x00, invalidSignatureSelector) }
                case 2 { mstore(0x00, invalidSignatureLengthSelector) }
                case 3 { mstore(0x00, invalidSignatureSSelector) }
                revert(0x00, 0x20)
            }
        }

        if (recoveredAddress == address(0)) {
            revert LibSignatureChecker__InvalidRecoveredAddress();
        }

        LibGovernance.Storage storage gs = LibGovernance.getGovernanceStorage();

        bool isMember = gs.members.contains(recoveredAddress);
        if (!isMember) {
            revert LibSignatureChecker__RecoveredAddressNotMember(recoveredAddress);
        }
    }

    function checkSignaturesUniquenessAndCount(bytes[] memory signatures) internal {
        LibGovernance.Storage storage gs = LibGovernance.getGovernanceStorage();
        if (signatures.length != gs.members.length()) {
            revert LibSignatureChecker__InvalidSignaturesCount(signatures.length);
        }
        Storage storage sgs = getSignatureCheckerStorage();
        for (uint256 i = 0; i < signatures.length;) {
            bool isUnique = sgs.uniqueSet.add(keccak256(signatures[i]));
            if (!isUnique) {
                revert LibSignatureChecker__InvalidSignaturesNotUnique();
            }
            assembly {
                i := add(1, i)
            }
            sgs.uniqueSet.remove(keccak256(signatures[i]));
        }
    }
}
