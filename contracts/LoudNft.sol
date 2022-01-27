// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import './ERC2981PerTokenRoyalties.sol';

contract LoudNft is ERC1155, ERC2981PerTokenRoyalties {
    using SafeMath for uint256;
    using Address for address;

    IERC20 private _token;

    uint256 counter = 1;
    address public owner;

    event Loud(address indexed account, uint256 nftId);

    event LoudBatch(address indexed account, uint256[] nftIds);

    constructor (address token, string memory name, string memory symbol, string memory tokenURIPrefix) ERC1155 (name, symbol) {
        owner = msg.sender;
        _token = IERC20(token);
        _setTokenURIPrefix(tokenURIPrefix);

    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /** @dev change the Ownership from current owner to newOwner address
        @param newOwner : newOwner address */

    function ownerTransfership(address newOwner) public onlyOwner returns(bool){
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
        return true;
    }

    function setBaseURIPrefix(string memory tokenURIPrefix) public onlyOwner{
        _setTokenURIPrefix(tokenURIPrefix);
    }

    /// @notice Mint amount token of type `id` to msg.sender
    /// @param amount amount of the token type to mint
    /// @param royaltyValue the royalties asked for (EIP2981)
    function mint(
        uint256 amount,
        uint256 royaltyValue
    ) external {
        _mint(msg.sender, counter, amount, '');

        emit Loud(msg.sender, counter);

        if (royaltyValue > 0) {
            _setTokenRoyalty(counter, msg.sender, royaltyValue);
        }

        counter ++;
    }

    /// @notice Mint several tokens at once
    /// @param amounts array of amount to mint for each token type
    /// @param royaltyValues an array of royalties asked for (EIP2981)
    function mintBatch(
        uint256[] memory amounts,
        uint256[] memory royaltyValues
    ) external {
        require(
            ids.length == royaltyRecipients.length &&
                ids.length == royaltyValues.length,
            'ERC1155: Arrays length mismatch'
        );

        uint256[] memory ids = new uint256[](amounts.length);

        for (uint256 i; i < amounts.length; i++) {
            ids[i] = counter + i;
        }

        _mintBatch(msg.sender, ids, amounts, '');

        for (uint256 i; i < amounts.length; i++) {
            if (royaltyValues[i] > 0) {
                _setTokenRoyalty(
                    counter + i,
                    msg.sender,
                    royaltyValues[i]
                );
            }
        }

        emit LoudBatch(msg.sender, ids);

        counter += amounts.length;
    }

    function purchase(uint256 id, uint256 price, address from) external {
        require(price > 0, "value below price");

        (to, amount) = royaltyInfo(id, price);
        _token.approve(to, amount);
        _token.transfer(to, amount);
        _token.approve(from, price - amount);
        _token.transfer(from, price - amount);
    }

    function burn(uint256 tokenId, uint256 supply) public {
        _burn(msg.sender, tokenId, supply);
    }

    function burnBatch(address account, uint256[] memory tokenIds, uint256[] memory amounts) public {
        _burnBatch(account, tokenIds, amounts);
    }
}