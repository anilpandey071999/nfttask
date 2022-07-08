// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "@openzeppelin/contracts/utils/Counters.sol";

contract INF is ERC721 {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    mapping(uint256=>string) private _tokenURI;

    constructor() ERC721("INF", "INF") {
         _tokenIdCounter.increment();
    }

    function mint(address to,string memory uri) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenURI[_tokenIdCounter.current()] = uri;
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

     function totalSupply() public view returns (uint256) {
       return _tokenIdCounter.current();
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURI[tokenId];
    }

}