// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library WrapperStorage {
    struct Layout {
      // Variables
      uint256 nTokens;                              // Number of ERC-20 tokens registered
      mapping (address => uint256) addressToID;     // Maps the ERC-20 addresses to their metaERC20 id
      mapping (uint256 => address) IDtoAddress;     // Maps the metaERC20 ids to their ERC-20 address
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256('token.wrapper.storage.ERC1155');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}
