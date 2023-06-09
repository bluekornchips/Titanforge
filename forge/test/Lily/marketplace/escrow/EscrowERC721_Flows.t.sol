// SPDX-License-Identifier: None
pragma solidity ^0.8.19;

import "forge-std/Test.sol";

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {EscrowERC721} from "Lily/marketplace/escrow/EscrowERC721.sol";
import {ILilyERC721, LilyERC721} from "Lily/ERC/ERC721/LilyERC721.sol";

import {IEscrowERC721_Test} from "./IEscrowERC721.t.sol";

contract EscrowERC721_Test is IEscrowERC721_Test, Test {
    LilyERC721 tokensOne;
    LilyERC721 tokensTwo;
    EscrowERC721 escrow;

    uint32 public escrow_max_items;

    function setUp() public {
        escrow = new EscrowERC721();
        escrow_max_items = escrow.MAX_ITEMS();

        //tokensOne
        tokensOne = new LilyERC721(NAME, SYMBOL, escrow_max_items, BASE_URI);
        tokensOne.setPublicMintEnabled(true);

        //tokensTwo
        tokensTwo = new LilyERC721(NAME, SYMBOL, escrow_max_items, BASE_URI);
        tokensTwo.setPublicMintEnabled(true);

        escrow.setVendorStatus(address(tokensOne), true);
        escrow.setVendorStatus(address(tokensTwo), true);
    }

    //#region Single Contract Tests
    function test_resaleFlow_ShouldPass() public {
        uint32 tokenId = mintAndApprove();

        uint32 itemId = escrow.createItem(address(tokensOne), tokenId);
        escrow.createPurchase(address(tokensOne), tokenId, address(w_main));

        vm.prank(address(w_main));
        escrow.claimItem(address(tokensOne), tokenId);
        assertEq(tokensOne.ownerOf(tokenId), address(w_main));

        vm.prank(address(w_main));
        tokensOne.approve(address(escrow), tokenId);

        vm.prank(address(w_main));
        itemId = escrow.createItem(address(tokensOne), tokenId);

        escrow.createPurchase(address(tokensOne), tokenId, address(this));

        escrow.claimItem(address(tokensOne), tokenId);
        assertEq(tokensOne.ownerOf(tokenId), address(this));
    }

    function test_BuyAndSellFlowMultipleTimes_UnderMaxLimit_ShouldPass()
        public
    {
        escrow_max_items = escrow.MAX_ITEMS();

        // Mint escrow_max_items tokens
        uint32[] memory tokenIds = new uint32[](escrow_max_items);
        for (uint32 i; i < escrow_max_items; i++) {
            tokenIds[i] = mintAndApprove();
        }

        // Create escrow_max_items items
        uint32[] memory itemIds = new uint32[](escrow_max_items);
        for (uint32 i; i < escrow_max_items; i++) {
            itemIds[i] = escrow.createItem(address(tokensOne), tokenIds[i]);
        }

        // Create escrow_max_items purchases
        for (uint32 i; i < escrow_max_items; i++) {
            escrow.createPurchase(
                address(tokensOne),
                tokenIds[i],
                address(w_main)
            );
        }

        // Claim escrow_max_items items
        for (uint32 i; i < escrow_max_items; i++) {
            vm.prank(address(w_main));
            escrow.claimItem(address(tokensOne), tokenIds[i]);
        }

        // List the same escrow_max_items items again
        for (uint32 i; i < escrow_max_items; i++) {
            vm.prank(address(w_main));
            tokensOne.approve(address(escrow), tokenIds[i]);
            vm.prank(address(w_main));
            itemIds[i] = escrow.createItem(address(tokensOne), tokenIds[i]);
        }

        // Create escrow_max_items purchases
        for (uint32 i; i < escrow_max_items; i++) {
            escrow.createPurchase(
                address(tokensOne),
                tokenIds[i],
                address(this)
            );
        }

        // Claim escrow_max_items items
        for (uint32 i; i < escrow_max_items; i++) {
            vm.prank(address(this));
            escrow.claimItem(address(tokensOne), tokenIds[i]);
        }
    }

    //#endregion

    //#region Multiple Contracts Tests
    function test_ListingOneTokenFromEitherContract_ShouldPass() public {
        // console.log("Escrow Address:%s", address(escrow));
        uint32 tokensOne_tokenId = mintPrank(w_main, tokensOne);
        uint32 tokensTwo_tokenId = mintPrank(w_main, tokensTwo);

        assertEq(
            IERC721(tokensOne).ownerOf(tokensOne_tokenId),
            address(w_main)
        );
        assertEq(
            IERC721(tokensTwo).ownerOf(tokensTwo_tokenId),
            address(w_main)
        );

        approvePrank(w_main, tokensOne, tokensOne_tokenId);
        approvePrank(w_main, tokensTwo, tokensTwo_tokenId);

        vm.prank(w_main);
        escrow.createItem(address(tokensOne), tokensOne_tokenId);

        vm.prank(w_main);
        escrow.createItem(address(tokensTwo), tokensTwo_tokenId);

        assertEq(
            IERC721(tokensOne).ownerOf(tokensOne_tokenId),
            address(escrow)
        );
        assertEq(
            IERC721(tokensTwo).ownerOf(tokensTwo_tokenId),
            address(escrow)
        );

        // Create a purchase for w_one for both tokens
        escrow.createPurchase(
            address(tokensOne),
            tokensOne_tokenId,
            address(w_one)
        );

        escrow.createPurchase(
            address(tokensTwo),
            tokensTwo_tokenId,
            address(w_one)
        );

        // Claim both tokens
        vm.prank(w_one);
        escrow.claimItem(address(tokensOne), tokensOne_tokenId);
        vm.prank(w_one);
        escrow.claimItem(address(tokensTwo), tokensTwo_tokenId);

        // Check that both tokens are owned by w_one
        assertEq(IERC721(tokensOne).ownerOf(tokensOne_tokenId), address(w_one));
        assertEq(IERC721(tokensTwo).ownerOf(tokensTwo_tokenId), address(w_one));
    }

    //#endregion

    //#region Helpers
    function mintAndApprove() internal returns (uint32) {
        uint32 tokenId = tokensOne.mint();
        tokensOne.approve(address(escrow), tokenId);
        return tokenId;
    }

    function mintPrank(
        address pranker,
        LilyERC721 ercContract
    ) internal returns (uint32) {
        vm.prank(pranker);
        return ercContract.mint();
    }

    function approvePrank(
        address pranker,
        LilyERC721 ercContract,
        uint32 tokenId
    ) internal {
        vm.prank(pranker);
        IERC721(ercContract).approve(address(escrow), tokenId);
    }
    //#endregion
}
