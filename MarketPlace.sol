// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./INF.sol";
import "./IDA.sol";

contract MarketPlace {
    using Counters for Counters.Counter;

    Counters.Counter private _totalNft;
    address public nftContract;
    address public tokenContract;
    mapping(uint256 => MarketItem) public idToMarketItem;
    mapping(uint256 => uint256[]) public idTobetingPrtice;
    mapping(uint256 => address[]) public idTobettingAddress;

    struct MarketItem {
        uint256 nftID;
        uint256 price;
        address seller;
        string uri;
        bool openForSell;
        bool sold;
        bool openForAuction;
        uint256 stratAutionTiming;
        uint256 endAutionTiming;
        uint256 autionBasePrice;
    }

    constructor(
        address _nftContract,
        address _IDA
    ) {
        nftContract = _nftContract;
        tokenContract = _IDA;
    }

    function compare(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
    /*
        addNftCollection by this function you list nft for Aution by seting 
        _openForAuction as true will get listed for 
        aution
        NOTE: give the market place contract approval by calling setApprovalForAll funtion from nft contract.
    */
    function addNftCollection(
        uint256 _price,
        uint256 _autionBasePrice,
        bool _openForAuction,
        uint256 _stratAutionTiming,
        uint256 _endAutionTiming,
        string memory _uri
    ) public {
        uint256 getNFTId = INF(nftContract).totalSupply();
        INF(nftContract).mint(msg.sender, _uri);
        idToMarketItem[_totalNft.current()] = MarketItem({
            nftID: getNFTId,
            price: _price,
            seller: msg.sender,
            uri: _uri,
            openForSell: true,
            sold: false,
            openForAuction: _openForAuction,
            stratAutionTiming: _stratAutionTiming,
            endAutionTiming: _endAutionTiming,
            autionBasePrice: _autionBasePrice
        });
        _totalNft.increment();
    }

    /*
        openAution by using this function user can place a bidding for the nft by passing marketid and betting price
        and tokens will in contract 
    */
    function openAution(uint256 _marketId, uint256 _bettingPrice) public {
        require(
            idToMarketItem[_marketId].endAutionTiming > block.timestamp,
            "Market_Contract: Auction should be open"
        );
        require(
            idToMarketItem[_marketId].autionBasePrice < _bettingPrice,
            "Market_Contract: Betting price can not be less then Auction base price"
        );
        require(
            IDA(tokenContract).allowance(msg.sender, address(this)) >
                _bettingPrice,
            "Market_Contract: Need More Allowance"
        );
        IDA(tokenContract).transferFrom(
            msg.sender,
            address(this),
            _bettingPrice
        );
        idTobetingPrtice[_marketId].push(_bettingPrice);
        idTobettingAddress[_marketId].push(msg.sender);
    }

    /*
    declareResult by only owner of nft can call this function and it can only be called after aution time ends get's over.
    the higher bidder will get the nft and 
    in case of nft auction doesn't has any bidder by calling this function it will list for normal sall
    */
    function declareResult(uint256 _marketId) public {
        require(
            idToMarketItem[_marketId].endAutionTiming < block.timestamp,
            "Market_Contract: Auction should be open"
        );
        require(INF(nftContract).ownerOf(idToMarketItem[_marketId].nftID) == msg.sender,"Market_Contract: Only NFT owner can declare the result of the aution ");
        if (idTobetingPrtice[_marketId].length != 0) {
            uint256 highestBider = 0;
            for (
                uint256 index = idTobetingPrtice[_marketId].length - 1;
                index > 0;
                index--
            ) {
                if (
                    idTobetingPrtice[_marketId][index] >
                    idTobetingPrtice[_marketId][index - 1]
                ) {
                    highestBider = index;
                }
            }

            ERC20(tokenContract).transfer(
                idToMarketItem[_marketId].seller,
                idTobetingPrtice[_marketId][highestBider]
            );
            ERC721(nftContract).transferFrom(
                idToMarketItem[_marketId].seller,
                idTobettingAddress[_marketId][highestBider],
                _marketId
            );
            idToMarketItem[_marketId].seller = idTobettingAddress[_marketId][
                highestBider
            ];
            idToMarketItem[_marketId].openForSell = false;
            idToMarketItem[_marketId].openForAuction = false;
            idToMarketItem[_marketId].sold = true;
        } else {
            idToMarketItem[_marketId].openForAuction = false;
        }
    }

    /*
    buynft will help user to buy nft's 
    NOTE:before buying give the marketplace contract of an approval for nft and erc20 token contract
    only then user successfull can buy the nft
    */
    function buynft(
        address from,
        address to,
        uint256 marketid,
        uint256 nftid,
        uint256 amount
    ) public {
        require(
            idToMarketItem[marketid].price <= amount,
            "Market_Contract: Please pay listed amount"
        );
        ERC20(tokenContract).transferFrom(to, from, amount);
        ERC721(nftContract).transferFrom(from, to, nftid);
        idToMarketItem[marketid].seller = to;
        idToMarketItem[marketid].openForSell = false;
        idToMarketItem[marketid].sold = true;
    }

    /*
    getListedNft will return all the nft listed for sale
    */
    function getListedNft() public view returns (MarketItem[] memory) {
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for (uint256 index = 0; index < _totalNft.current(); index++) {
            if (idToMarketItem[index].openForSell) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 index = 0; index < _totalNft.current(); index++) {
            if (idToMarketItem[index].openForSell) {
                MarketItem storage currentItem = idToMarketItem[index];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /*
    getAllNft will all the nfts  
    */
    function getAllNft() public view returns (MarketItem[] memory) {
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for (uint256 index = 0; index < _totalNft.current(); index++) {
            if (idToMarketItem[index].seller == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        if (itemCount > 0) {
            for (uint256 index = 0; index < _totalNft.current(); index++) {
                if (idToMarketItem[index].seller == msg.sender) {
                    MarketItem storage currentItem = idToMarketItem[index];
                    items[currentIndex] = currentItem;
                    currentIndex += 1;
                }
            }
        }
        return items;
    }

    /*
    listforsale fuction can only called by nft owners for listing and unlisting from reselling  
    */
    function listForSale(uint256 nftId, uint256 marketid, uint256 price) public {
        require(marketid < _totalNft.current(), "Market_Contract: Invalid Index ");
        require(INF(nftContract).ownerOf(nftId) == msg.sender,"Market_Contract: Only NFT owner can list for sale ");
        idToMarketItem[marketid].openForSell = !idToMarketItem[marketid].openForSell;
        idToMarketItem[marketid].price = price;
    }


    function totalNft() external view returns (uint256 totalNfts) {
        return _totalNft.current();
    }
}
