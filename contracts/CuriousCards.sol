// // SPDX-License-Identifier: GPL-3.0
// // TODO
// // Make the thing actually anon? or rename to curious cards idk
// // Add a require max 2.5% fee to protocol fee
// // Mint a copy to the replier?
// // SVG clean line wrapping

// pragma solidity >=0.7.0 <0.9.0;

// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
// import "@openzeppelin/contracts/utils/Base64.sol";
// import "@openzeppelin/contracts/utils/Strings.sol";


// import "@openzeppelin/contracts/access/Ownable.sol";
  
// interface IProfileNFT {
//   function ownerOf(uint) external view returns (address);
//   function getHandle(uint) external view returns (string memory);
// } 

// contract CuriousCardsURI {
//     CuriousCards curiouscardscontract;

//     constructor(CuriousCards _curiouscardscontract) {
//       curiouscardscontract = _curiouscardscontract;
//     }

//     function tokenURI(uint256 tokenId)
//     public
//     view
//     virtual
//     returns (string memory)
//   {
//     string memory question = curiouscardscontract.question(tokenId);
//     string memory answer = curiouscardscontract.answer(tokenId);
//     string memory replier = curiouscardscontract.getHandle(curiouscardscontract.replierProfileId(tokenId));
//     string[5] memory parts;
//     parts[0] = '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><rect width="100%" height="100%" fill="black"/><defs><path id="path1" d="M10,30 H490 M10,60 H490 M10,90 H490 M10,120 H490 M10,150 H490 M10,180 H490"></path><path id="path2" d="M10,240 H490 M10,270 H490 M10,300 H490 M10,330 H490 M10,360 H490 M10,390 H490"></path></defs><use xlink:href="#path1" x="0" y="35" stroke="transparent" stroke-width="1" /><use xlink:href="#path2" x="0" y="35" stroke="transparent" stroke-width="1" /><text transform="translate(0,35)" fill="yellow" font-size="12" font-family="monospace"><textPath xlink:href="#path1">';

//     parts[1] = string(abi.encodePacked("Anon:", " ", question));

//     parts[2] = '</textPath><textPath xlink:href="#path2">';

//     parts[3] = string(abi.encodePacked(replier, ": ", answer));

//     parts[4] = '</textPath></text></svg>';

//     string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));

//     string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "AnonCard #', Strings.toString(tokenId), '", "description": "Ask anything to any Lens profile.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
//     output = string(abi.encodePacked('data:application/json;base64,', json));

//     return output;
//   }
// }

// contract CuriousCards is ERC721Royalty, ERC721Enumerable, Ownable {
//   uint tokenCounter;
//   bool public paused;
//   IProfileNFT ProfileNFT;

//   CuriousCardsURI curiouscardsuri;


//   mapping(uint256 => uint256[]) public profileIdToQuestions;
//   mapping(uint256 => uint256) public askFee;
//   mapping(uint256 => string) public question;
//   mapping(uint256 => uint256) public questionFee;
//   mapping(uint256 => uint256) public timestamp;
//   mapping(uint256 => string) public answer;
//   mapping(uint256 => uint256) public replierProfileId;
//   mapping(uint256 => bool) public isActive;
//   mapping(uint256 => bool) public isReplied;
//   mapping(uint256 => uint256) public rewards;
//   mapping(uint => uint) public tokenIdToIndex;
//   mapping(uint => uint) public amountReplied;
  
//   uint protocolFee = 250; //2.5%
//   uint protocolPool;
//   uint textMaxLength = 400;

//   constructor(IProfileNFT _ProfileNFT) ERC721("CuriousCards0", "CCARD") {
//     ProfileNFT = _ProfileNFT;
//   }

//   function setCuriouscardsUri(CuriousCardsURI _uri) public onlyOwner {
//     curiouscardsuri = _uri;
//   }


//   function mint(string memory _question, uint profileId) public payable {
//     require(!paused, "Mint is on Pause");
//     require(msg.value == askFee[profileId],"ask fee not paid");
//     require(isActive[profileId], "Profile inactive.");
//     require(bytes(_question).length <= textMaxLength, "Question too long.");
//     require(bytes(_question).length > 0, "Must ask something.");
//     uint tokenId = tokenCounter + 1;
//     tokenCounter += 1;
//     _safeMint(msg.sender, tokenId);
//     question[tokenId] = _question;
//     timestamp[tokenId] = block.timestamp;
//     replierProfileId[tokenId] = profileId;
//     tokenIdToIndex[tokenId] = profileIdToQuestions[profileId].length;
//     profileIdToQuestions[profileId].push(tokenId);
//     questionFee[tokenId] = msg.value;
//     _setTokenRoyalty(tokenId, msg.sender, 500);
//   }

//   function reply(string memory _answer, uint tokenId) public {
//     uint profileId = replierProfileId[tokenId];
//     require(msg.sender == ProfileNFT.ownerOf(profileId), "Must own the profile NFT to reply.");
//     require(!isReplied[tokenId], "Already replied");
//     require(bytes(_answer).length <= textMaxLength, "Reply too long.");
//     require(bytes(_answer).length > 0, "Must reply something.");
//     answer[tokenId] = _answer;
//     uint price = questionFee[tokenId];
//     uint commission =  price * protocolFee / 10000;
//     protocolPool += commission;
//     rewards[profileId] += price - commission;
//     isReplied[tokenId] = true;
//     amountReplied[profileId] += 1;
//   }

//   function claimRewards(uint profileId) external payable {
//     require(msg.sender == ProfileNFT.ownerOf(profileId), "Must own the profile NFT to reply.");
//     require(rewards[profileId] > 0, "No rewards to claim.");
//     payable(msg.sender).transfer(rewards[profileId]);
//     rewards[profileId] = 0;
//   }
  
//   function setTextMaxLength(uint _length) external onlyOwner {
//     textMaxLength = _length;
//   }
//   function setProtocolFee(uint _fee) external onlyOwner {
//     require(_fee <= 500, "fee too high");
//     protocolFee = _fee;
//   }

//   function claimProtocolFees() external payable onlyOwner {
//     payable(msg.sender).transfer(protocolPool);
//     protocolPool = 0;
//   }

//   function redeem(uint questionId) external {
//     require(msg.sender == ownerOf(questionId), "Only owner can redeem.");
//     require(!isReplied[questionId], "Question is already answered.");
//     require(block.timestamp > timestamp[questionId] + 7 days, "Wait 7 days before redeem.");
//     uint index = tokenIdToIndex[questionId];
//     remove(index, replierProfileId[questionId]);
//     payable(msg.sender).transfer(questionFee[questionId]);
//     _burn(questionId);
//   }

//   function updateProfile(bool _isActive, uint _askFee, uint profileId) public {
//     require(msg.sender == ProfileNFT.ownerOf(profileId),"Must own the profile NFT.");
//     isActive[profileId] = _isActive;
//     askFee[profileId] = _askFee;
//   }
  
//   function getHandle(uint profileId) external view returns (string memory) {
//     return ProfileNFT.getHandle(profileId);
//   }

//   function fetchQuestionsId(uint profileId) public view returns (uint[] memory){
//     return profileIdToQuestions[profileId];
//   }

//   function remove(uint _index, uint profileId) internal {
//     uint256[] storage questions = profileIdToQuestions[profileId];
//     questions[_index] = questions[questions.length - 1];
//     tokenIdToIndex[questions[_index]] = _index;
//     questions.pop();
//   }

//   function walletOfUser(address _user)
//     public
//     view
//     returns (uint256[] memory)
//   {
//     uint256 ownerTokenCount = balanceOf(_user);
//     uint256[] memory tokenIds = new uint256[](ownerTokenCount);
//     for (uint256 i; i < ownerTokenCount; i++) {
//       tokenIds[i] = tokenOfOwnerByIndex(_user, i);
//     }
//     return tokenIds;
//   }
    
//   function tokenURI(uint256 tokenId)
//     public
//     view
//     virtual
//     override
//     returns (string memory)
//   {
//     require(
//       _exists(tokenId),
//       "ERC721Metadata: URI query for nonexistent token"
//     );
//     return curiouscardsuri.tokenURI(tokenId);
//   }
  

//   function tokenExists(uint256 _id) external view returns (bool) {
//       return (_exists(_id));
//   }
//   function pause(bool _state) public onlyOwner {
//     paused = _state;
//   }

//   function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
//     _setDefaultRoyalty(receiver, feeNumerator);
//   }

//   function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeNumerator) public onlyOwner {
//     _setTokenRoyalty(tokenId, receiver, feeNumerator);
//   }

//   function supportsInterface(bytes4 interfaceId) public view override(ERC721Enumerable, ERC721Royalty) returns (bool) {
//     return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
//   }

//   function _burn(uint256 tokenId) internal virtual override(ERC721, ERC721Royalty) {
//     super._burn(tokenId);
//      _resetTokenRoyalty(tokenId);
//   }

//   function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721Enumerable, ERC721) {
//     super._beforeTokenTransfer(from, to, tokenId);
//   }
  
// }