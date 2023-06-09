// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {LilyERC721} from "Lily/ERC/ERC721/LilyERC721.sol";
import {ILilyERC721Airdroppable} from "./ILilyERC721Airdroppable.sol";

contract LilyERC721Airdroppable is ILilyERC721Airdroppable, LilyERC721 {
    /// @dev A counter for tracking the token ID
    uint16 public _airDropCounter;

    /**
     * @notice Constructor to initialize the LilyERC721Airdroppable contract
     * @param name_ The name of the ERC721 token
     * @param symbol_ The symbol of the ERC721 token
     * @param max_supply_ The maximum supply of ERC721 tokens
     * @param baseURILocal_ The base URI for the metadata of the ERC721 tokens
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint32 max_supply_,
        string memory baseURILocal_
    ) LilyERC721(name_, symbol_, max_supply_, baseURILocal_) {}

    /**
     * @notice Mints and distributes ERC721 tokens as airdrops to the specified recipients
     * @dev Can only be called by the owner of the contract
     * @param airdrops_ An array of Airdrop structs containing the recipient address and token count
     */
    function deliverDrop(Airdrop[] memory airdrops_) public onlyOwner {
        uint32 tokenCount;
        uint32 i;

        unchecked {
            do {
                tokenCount += airdrops_[i].tokenCount;
                if (tokenCount > maxSupply) revert MaxSupply_Reached();
                if (airdrops_[i].recipient == address(0))
                    revert AirdropRecipientCannotBeZero();
                if (airdrops_[i].tokenCount < 1)
                    revert AirdropTokenCountCannotBeLTOne();

                i++;
            } while (i < airdrops_.length);
        }

        i = 0; // Reset i

        uint32 tokenId = tokenIdCounter;

        Airdropped[] memory airdropped = new Airdropped[](airdrops_.length);
        unchecked {
            do {
                Airdrop memory airdrop = airdrops_[i];

                airdropped[i].recipient = airdrop.recipient;
                airdropped[i].tokenIds = new uint32[](airdrop.tokenCount);

                uint32 j;
                do {
                    _mint(airdrop.recipient, ++tokenId);
                    airdropped[i].tokenIds[j] = tokenId;
                    ++j;
                } while (j < airdrop.tokenCount);

                ++i;
            } while (i < airdrops_.length);
        }

        tokenIdCounter = tokenId;

        emit AirdropDelivered(uint8(++_airDropCounter), airdropped);
    }
}
