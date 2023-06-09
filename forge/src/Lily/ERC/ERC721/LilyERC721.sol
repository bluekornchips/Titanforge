// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {Pausable} from "openzeppelin-contracts/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {IERC721Receiver} from "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import {ERC721, ERC721Enumerable} from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import {ILilyERC721} from "./ILilyERC721.sol";

contract LilyERC721 is
    Ownable,
    Pausable,
    ILilyERC721,
    IERC721Receiver,
    ReentrancyGuard,
    ERC721Enumerable
{
    /// @dev The ceiling for the total supply of the token
    uint32 public constant SUPPLY_CEILING = 1_000_000;

    /// @dev A counter for tracking the token ID.
    uint32 public tokenIdCounter;

    /// @dev The maximum supply of the token. Defaults to 1,000,000.
    uint32 public maxSupply = 1_000_000;

    /// @dev A flag for enabling or disabling public minting
    bool public publicMintEnabled;

    /// @dev A flag for enabling or disabling burning of tokens
    bool public burnEnabled;

    /// @dev A base URI for metadata of the token, to be concatenated with the token ID
    string public baseURILocal;

    constructor(
        string memory name_,
        string memory symbol_,
        uint32 maxSupply_,
        string memory baseURILocal_
    ) ERC721(name_, symbol_) {
        maxSupply = maxSupply_;
        baseURILocal = baseURILocal_;
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev Pauses the contract.
     *
     * Requirements:
     * - The contract must not already be paused.
     * - Can only be called by the owner of the contract.
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
     * @dev Unpauses the contract.
     *
     * Requirements:
     * - The contract must be paused.
     * - Can only be called by the owner of the contract.
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Sets the burn status of the contract.
     *
     * Requirements:
     * - Can only be called by the owner of the contract.
     *
     * @param status A bool indicating whether or not burning is enabled.
     */
    function setBurnEnabled(bool status) public onlyOwner {
        burnEnabled = status;
        emit BurnEnabledChanged(status);
    }

    /**
     * @dev Sets the public minting status of the Lily ERC721 token.
     *
     * Requirements:
     * - The caller must be the owner of the contract.
     *
     * @param status The new public minting status.
     */
    function setPublicMintEnabled(bool status) public onlyOwner {
        publicMintEnabled = status;
        emit PublicMintEnabledChanged(status);
    }

    /**
     * @dev Sets the maximum supply of the Lily ERC721 token.
     *
     * Requirements:
     * - The caller must be the owner of the contract.
     * - The increased supply must be greater than 0.
     * - The increased supply must be greater than the current maximum supply.
     * - The increased supply must not exceed the supply ceiling.
     *
     * Emits a {MaxSupplyChanged} event indicating the updated maximum supply.
     *
     * @param increasedSupply The new maximum supply.
     */
    function setMaxSupply(uint32 increasedSupply) public onlyOwner {
        if (
            increasedSupply <= 0 ||
            increasedSupply < totalSupply() ||
            increasedSupply > SUPPLY_CEILING
        ) {
            revert MaxSupply_Invalid();
        }

        maxSupply = increasedSupply;

        emit MaxSupplyChanged(increasedSupply);
    }

    /**
     * @dev Sets the base URI for the Lily ERC721 token metadata.
     *
     * Requirements:
     * - The caller must be the owner of the contract.
     *
     * Emits a {BaseURIChanged} event indicating the updated base URI.
     *
     * @param baseURI_ The new base URI for the token metadata.
     */
    function setBaseURI(string calldata baseURI_) public onlyOwner {
        baseURILocal = baseURI_;
        emit BaseURIChanged(baseURILocal);
    }

    /**
     * @dev Mints a new token and assigns it to the caller's address.
     *
     * Requirements:
     * - Public minting must be enabled.
     * - The contract must not be paused.
     *
     * @return The id of the newly minted token.
     */
    function mint() public virtual returns (uint32) {
        if (!publicMintEnabled) revert PublicMintDisabled();
        return lilyMint(_msgSender());
    }

    /**
     * @dev Burns a token.
     *
     * Requirements:
     * - Burning must be enabled.
     * - The token must exist.
     * - The caller must either own the token or be approved to burn it.
     * - The contract must not be paused.
     *
     * @param tokenId The ID of the token to be burned.
     */
    function burn(uint32 tokenId) public virtual whenNotPaused nonReentrant {
        if (!burnEnabled) {
            revert BurnDisabled();
        }
        if (!_isApprovedOrOwner(_msgSender(), tokenId)) {
            revert NotApprovedOrOwner();
        }
        _burn(tokenId);
    }

    /**
     * @dev Returns the base URI for all tokens.
     * @return A string representing the base URI.
     */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI();
    }

    /**
     * @dev Returns the base URI for this contract.
     * @return A string representing the base URI.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURILocal;
    }

    /**
     * @dev Mints a new Lily ERC721 token and assigns it to the specified address.
     *
     * Requirements:
     * - The contract must not be paused.
     * - The maximum supply has not been reached.
     *
     * @param to The address to assign the newly minted token to.
     * @return tokenId - The ID of the newly minted token.
     */
    function lilyMint(
        address to
    ) internal whenNotPaused nonReentrant returns (uint32 tokenId) {
        if (tokenIdCounter >= maxSupply) {
            revert MaxSupply_Reached();
        }

        _mint(to, ++tokenIdCounter);

        return tokenIdCounter;
    }
}
