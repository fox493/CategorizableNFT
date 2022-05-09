// SPDX-License-Identifier: MIT
// NftClass Template Contract v0.0.1
// Creator: Fox

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "hardhat/console.sol";

/**
 * @dev Assume that you want to release a set of NFT, while there's a several
 * series of your NFT, such as collection, poap, consumable token and etc.
 * Now you need to devide your NFT into several categories, correspond the NftClass of the contract
 * 
 * There still are lot of places to be consummate and optimize
 */

contract CategorizableNft is ERC721, Ownable {
    struct NftClass {
        // determine if token could be transfered
        bool transferable;
        // determine if token could be minted again by the one has minted
        bool mintable;
        // determine if toke could be burned
        bool burnable;
        // determine if the metadata of class can be modified
        bool frozen;
        // owner of the class
        address owner;
        // the next token id of the class
        uint64 currentIndex;
        // the amount of token has been burned
        uint64 burnedAmount;
        // the amount of token can be minted per transaction
        uint64 maxPerTx;
        // total amount of token
        uint64 maxSupply;
        // the price of one token
        uint128 price;
        // Mapping owner address to token count
        mapping(address => uint256) balances;
    }

    uint256 public nextTokenId = 0;

    uint256 public nextClassId = 0;

    // Mapping class id to class data
    mapping(uint256 => NftClass) private _classData;

    // Mapping token ID to Class Id
    mapping(uint256 => uint256) private _tokenClass;

    constructor(string memory _tokenName, string memory _tokenSymbol)
        ERC721(_tokenName, _tokenSymbol)
    {}

    /**
     * add a nft class
     * the currentIndex, burnedAmount will be set to a default value 0
     */
    function addNftClass(
        bool _transferable,
        bool _mintable,
        bool _burnable,
        bool _frozen,
        address _owner,
        uint64 _maxPerTx,
        uint64 _maxSupply,
        uint128 _price
    ) external onlyOwner {
        NftClass storage class = _classData[nextClassId++];
        class.transferable = _transferable;
        class.mintable = _mintable;
        class.burnable = _burnable;
        class.frozen = _frozen;
        class.owner = _owner;
        class.currentIndex = 0;
        class.burnedAmount = 0;
        class.maxPerTx = _maxPerTx;
        class.maxSupply = _maxSupply;
        class.price = _price;
    }

    // revert when caller is not the owner of nft class
    modifier isOwnerOfClass(uint256 _classId) {
        require(_classData[_classId].owner == msg.sender, "Not the owner of the class!");
        _;
    }

    // revert when someone still want to change the metadata of a nft class which has been frozen
    modifier isClassFrozen(uint256 _classId) {
        require(!_classData[_classId].frozen, "Class has been frozen!");
        _;
    }

    // revert when the classId doesn't exist
    modifier validClassId(uint256 _classId) {
        require(_classId < nextClassId, "Invalid class id!");
        _;
    }

    // revert when the tokenId doesn't exist
    modifier validTokenId(uint256 _tokenId) {
        require(_tokenId < nextTokenId, "Invalid token id!");
        _;
    }

    /**
     * Check if the nft has been sold out
     * Check if the amount of minting is exceed the limit
     * Check if the amount of ether is sent correctly
     */
    modifier mintCompliance(uint256 _mintAmount, uint256 _classId) {
        require(
            totalSupplyOfClass(_classId) + _mintAmount <=
                _classData[_classId].maxSupply,
            "Max supply exceed!"
        );
        require(
            _mintAmount <= _classData[_classId].maxPerTx,
            "Can not mint this many!"
        );
        require(
            msg.value == _mintAmount * _classData[_classId].price,
            "Wrong amount of ether!"
        );
        _;
    }

    /**
     *@param _mintAmount the amount of nft want to be minted
     *@param _classId which class of nft want to mint
     */
    function mint(uint256 _mintAmount, uint256 _classId)
        public
        payable
        validClassId(_classId)
        mintCompliance(_mintAmount, _classId)
    {
        if (getBalancesOfClass(msg.sender, _classId) > 0) {
            require(_classData[_classId].mintable, "it's not mintable for you!");
        }
        for (uint256 i = 0; i < _mintAmount; i++) {
            _tokenClass[nextTokenId] = _classId;
            _safeMint(msg.sender, nextTokenId++);
        }
        _classData[_classId].balances[msg.sender] += _mintAmount;
        _classData[_classId].currentIndex += uint64(_mintAmount);
    }

    /**
     *@return totalSupply the summation of all classes of nfts (currently minted)
     */
    function totalSupply() public view returns (uint256) {
        uint256 total;
        unchecked {
            for (uint256 i = 0; i < nextClassId; i++) {
                total =
                    total +
                    _classData[i].currentIndex -
                    _classData[i].burnedAmount;
            }
            return total;
        }
    }

    /**
     *@return totalSupplyOfClass current supply of the specified class
     */
    function totalSupplyOfClass(uint256 _classId)
        public
        view
        validClassId(_classId)
        returns (uint256)
    {
        unchecked {
            return
                _classData[_classId].currentIndex -
                _classData[_classId].burnedAmount;
        }
    }

    function setOwnerOfClass(uint256 _classId, address _newOwner)
        external
        validClassId(_classId)
        onlyOwner
    {
        require(
            _newOwner != address(0),
            "Can't set ownership to zero address!"
        );
        _classData[_classId].owner = _newOwner;
    }
  
    /**
     *@notice once class is frozen, not one could 'unfreeze', 
     *  which means it would be frozen permanently
     */
    function freezeClass(uint256 _classId)
        external
        validClassId(_classId)
        isOwnerOfClass(_classId)
    {
        _classData[_classId].frozen = true;
    }

    function flipTransferable(uint256 _classId)
        external
        validClassId(_classId)
        isOwnerOfClass(_classId)
        isClassFrozen(_classId)
    {
        _classData[_classId].transferable = !_classData[_classId].transferable;
    }

    function flipBurnable(uint256 _classId)
        external
        validClassId(_classId)
        isOwnerOfClass(_classId)
        isClassFrozen(_classId)
    {
        _classData[_classId].burnable = !_classData[_classId].burnable;
    }

    function flipMintable(uint256 _classId)
        external
        validClassId(_classId)
        isOwnerOfClass(_classId)
        isClassFrozen(_classId)
    {
        _classData[_classId].mintable = !_classData[_classId].mintable;
    }

    function setMaxSupplyOfClass(uint256 _classId, uint64 _newMaxSupply)
        external
        validClassId(_classId)
        isOwnerOfClass(_classId)
        isClassFrozen(_classId)
    {
        _classData[_classId].maxSupply = _newMaxSupply;
    }

    function setPriceOfClass(uint256 _classId, uint128 _newPrice)
        external
        validClassId(_classId)
        isOwnerOfClass(_classId)
        isClassFrozen(_classId)
    {
        _classData[_classId].price = _newPrice;
    }

    function setMaxPerTxOfClass(uint256 _classId, uint64 _newMaxPerTx)
        external
        validClassId(_classId)
        isOwnerOfClass(_classId)
        isClassFrozen(_classId)
    {
        _classData[_classId].maxPerTx = _newMaxPerTx;
    }

    function getCurrentSupplyOfClass(uint256 _classId)
        public
        view
        validClassId(_classId)
        returns (uint256)
    {
        return _classData[_classId].currentIndex;
    }

    function getClassOfToken(uint256 _tokenId)
        external
        view
        validTokenId(_tokenId)
        returns (uint256)
    {
        return _tokenClass[_tokenId];
    }

    function getClassData(uint256 _classId)
        external
        view
        validClassId(_classId)
        returns (
            bool transferable,
            bool mintalbe,
            bool burnable,
            bool frozen,
            address owner,
            uint64 maxPerTx,
            uint64 maxSupply,
            uint128 price
        )
    {
        NftClass storage class = _classData[_classId];
        return (
            class.transferable,
            class.mintable,
            class.burnable,
            class.frozen,
            class.owner,
            class.maxPerTx,
            class.maxSupply,
            class.price
        );
    }

    function getBalancesOfClass(address _owner, uint256 _classId)
        public
        view
        validClassId(_classId)
        returns (uint256)
    {
        return _classData[_classId].balances[_owner];
    }
}
