// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

interface IProfileNFT {
  function ownerOf(uint) external view returns (address);
  function getHandle(uint) external view returns (string memory);
} 


contract CuriousCardsURI {
    CuriousCardsV3 curiouscardscontract;

    constructor(CuriousCardsV3 _curiouscardscontract) {
      curiouscardscontract = _curiouscardscontract;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    returns (string memory)
  {
    string memory question = curiouscardscontract.question(tokenId);
    string memory answer = curiouscardscontract.answer(tokenId);
    string memory replier = curiouscardscontract.getHandle(curiouscardscontract.replierProfileId(tokenId));
    string memory asker = substring(string(toAsciiString(curiouscardscontract.asker(tokenId))),0,3);
    string[5] memory parts;

    parts[0] = '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><rect width="100%" height="100%" fill="black"/><defs><path id="path1" d="M10,30 H490 M10,60 H490 M10,90 H490 M10,120 H490 M10,150 H490 M10,180 H490"></path><path id="path2" d="M10,240 H490 M10,270 H490 M10,300 H490 M10,330 H490 M10,360 H490 M10,390 H490"></path></defs><use xlink:href="#path1" x="0" y="35" stroke="transparent" stroke-width="1" /><use xlink:href="#path2" x="0" y="35" stroke="transparent" stroke-width="1" /><text transform="translate(0,35)" fill="yellow" font-size="12" font-family="monospace"><textPath xlink:href="#path1">';

    parts[1] = string(abi.encodePacked("0x", asker, ": ", question));

    parts[2] = '</textPath><textPath xlink:href="#path2">';

    parts[3] = string(abi.encodePacked(replier, ": ", answer));

    parts[4] = '</textPath></text></svg>';

    string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));

    string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "CuriousCard #', Strings.toString(tokenId), '", "description": "Ask anything to Lens profiles.", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
    output = string(abi.encodePacked('data:application/json;base64,', json));

    return output;
  }

    function substring(string memory str, uint startIndex, uint endIndex) public pure returns (string memory ) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);            
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}


contract CuriousCardsV3 is Initializable, ERC721Upgradeable, ERC721EnumerableUpgradeable, PausableUpgradeable, OwnableUpgradeable, ERC721BurnableUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    CountersUpgradeable.Counter private _tokenIdCounter;

    IProfileNFT constant ProfileNFT = IProfileNFT(0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d);

    CuriousCardsURI curiouscardsuri;


    mapping(uint256 => uint256[]) public profileIdToQuestions;
    mapping(uint256 => uint256) public askFee;
    mapping(uint256 => string) public question;
    mapping(uint256 => uint256) public questionFee;
    mapping(uint256 => uint256) public timestamp;
    mapping(uint256 => string) public answer;
    mapping(uint256 => uint256) public replierProfileId;
    mapping(uint256 => bool) public isActive;
    mapping(uint256 => bool) public isReplied;
    mapping(uint256 => uint256) public rewards;
    mapping(uint => uint) public tokenIdToIndex;
    mapping(uint => uint) public amountReplied;
    
    uint protocolFee;
    uint protocolPool;
    uint textMaxLength;

    event QuestionAsked(address indexed _from, uint indexed _toprofileid, uint _id, string _questiontext);
    event QuestionReplied(uint indexed _fromprofileid, address indexed _to, uint _id, string _replytext);
    event ProfileUpdated(uint indexed _profileid, bool _isactive, uint _askfee);

    mapping(uint => address) public asker;
    uint redeemDuration;

    function initialize() initializer public {
        __ERC721_init("CuriousCards0", "CCARDS");
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        protocolFee = 250;
        textMaxLength = 400;
        redeemDuration = 3 days;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function setCuriouscardsUri(CuriousCardsURI _uri) public onlyOwner {
        curiouscardsuri = _uri;
    }


    function mint(string memory _question, uint profileId) public whenNotPaused payable {
        require(msg.value == askFee[profileId],"ask fee not paid");
        require(isActive[profileId], "Profile inactive.");
        require(bytes(_question).length <= textMaxLength, "Question too long.");
        require(bytes(_question).length > 0, "Must ask something.");
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        asker[tokenId] = msg.sender;
        question[tokenId] = _question;
        timestamp[tokenId] = block.timestamp;
        replierProfileId[tokenId] = profileId;
        tokenIdToIndex[tokenId] = profileIdToQuestions[profileId].length;
        profileIdToQuestions[profileId].push(tokenId);
        questionFee[tokenId] = msg.value;
        emit QuestionAsked(msg.sender, profileId, tokenId, _question);
    }

    function reply(string memory _answer, uint tokenId) public {
        uint profileId = replierProfileId[tokenId];
        require(msg.sender == ProfileNFT.ownerOf(profileId), "Must own the profile NFT to reply.");
        require(!isReplied[tokenId], "Already replied");
        require(bytes(_answer).length <= textMaxLength, "Reply too long.");
        require(bytes(_answer).length > 0, "Must reply something.");
        answer[tokenId] = _answer;
        uint price = questionFee[tokenId];
        uint commission =  price * protocolFee / 10000;
        protocolPool += commission;
        rewards[profileId] += price - commission;
        isReplied[tokenId] = true;
        amountReplied[profileId] += 1;
        emit QuestionReplied(profileId, msg.sender, tokenId, _answer);
    }

    function claimRewards(uint profileId) external payable {
        require(msg.sender == ProfileNFT.ownerOf(profileId), "Must own the profile NFT to reply.");
        require(rewards[profileId] > 0, "No rewards to claim.");
        payable(msg.sender).transfer(rewards[profileId]);
        rewards[profileId] = 0;
    }
    
    function setTextMaxLength(uint _length) external onlyOwner {
        textMaxLength = _length;
    }
    function setProtocolFee(uint _fee) external onlyOwner {
        require(_fee <= 500);
        protocolFee = _fee;
    }

    function setRedeemDuration(uint duration) external onlyOwner {
        redeemDuration = duration;
    }
    function claimProtocolFees() external payable onlyOwner {
        payable(msg.sender).transfer(protocolPool);
        protocolPool = 0;
    }

    function redeem(uint questionId) external {
        require(msg.sender == ownerOf(questionId), "Only owner can redeem.");
        require(!isReplied[questionId], "Question is already answered.");
        require(block.timestamp > timestamp[questionId] + redeemDuration, "Wait before redeem.");
        uint index = tokenIdToIndex[questionId];
        remove(index, replierProfileId[questionId]);
        payable(msg.sender).transfer(questionFee[questionId]);
        _burn(questionId);
    }

    function updateProfile(bool _isActive, uint _askFee, uint profileId) external {
        require(msg.sender == ProfileNFT.ownerOf(profileId),"Must own the profile NFT.");
        isActive[profileId] = _isActive;
        askFee[profileId] = _askFee;
        emit ProfileUpdated(profileId, _isActive, _askFee);
    }
    
    function getHandle(uint profileId) external view returns (string memory) {
        return ProfileNFT.getHandle(profileId);
    }

    function getRedeemDuration(uint questionId) external view returns (uint){
        if (timestamp[questionId] + redeemDuration > block.timestamp) {
            return timestamp[questionId] + redeemDuration - block.timestamp;
        } else {
            return 0;
        }
    }

    function fetchQuestionsId(uint profileId) external view returns (uint[] memory){
        return profileIdToQuestions[profileId];
    }

    function remove(uint _index, uint profileId) internal {
        uint256[] storage questions = profileIdToQuestions[profileId];
        questions[_index] = questions[questions.length - 1];
        tokenIdToIndex[questions[_index]] = _index;
        questions.pop();
    }

    function walletOfUser(address _user)
        public
        view
        returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_user);
        uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_user, i);
        }
        return tokenIds;
    }
        
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
        _exists(tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );
        return curiouscardsuri.tokenURI(tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

