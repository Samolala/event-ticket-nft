// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EventTicketNFT is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;

    uint256 private _nextTokenId;
    uint256 public constant MAX_SUPPLY = 100;
    uint256 public constant MAX_PER_WALLET = 5;
    uint256 public ethPrice = 0.01 ether;
    uint256 public erc20Price = 10 * 10**18;
    
    IERC20 public paymentToken;
    bool public useERC20 = false;
    
    string private baseURI;
    
    mapping(address => uint256) public mintedPerWallet;
    
    event TicketMinted(address indexed to, uint256 tokenId, string paymentMethod);
    event PriceUpdated(uint256 newEthPrice, uint256 newErc20Price);
    event PaymentTokenChanged(address newToken);
    event PaymentMethodSwitched(bool useERC20);
    
    constructor(
        string memory name,
        string memory symbol,
        string memory _baseURI,
        address initialOwner
    ) ERC721(name, symbol) Ownable(initialOwner) {
        baseURI = _baseURI;
    }
    
    function mint(uint256 quantity) external payable nonReentrant {
        require(quantity > 0 && quantity <= MAX_PER_WALLET, "Invalid quantity");
        require(mintedPerWallet[msg.sender] + quantity <= MAX_PER_WALLET, "Exceeds wallet limit");
        require(_nextTokenId + quantity <= MAX_SUPPLY, "Exceeds max supply");
        
        if (useERC20) {
            require(paymentToken != IERC20(address(0)), "ERC20 token not set");
            uint256 totalPrice = erc20Price * quantity;
            require(paymentToken.transferFrom(msg.sender, address(this), totalPrice), "Payment failed");
        } else {
            uint256 totalPrice = ethPrice * quantity;
            require(msg.value >= totalPrice, "Insufficient ETH");
            if (msg.value > totalPrice) {
                payable(msg.sender).transfer(msg.value - totalPrice);
            }
        }
        
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = _nextTokenId;
            _nextTokenId++;
            _safeMint(msg.sender, tokenId);
            mintedPerWallet[msg.sender]++;
            emit TicketMinted(msg.sender, tokenId, useERC20 ? "ERC20" : "ETH");
        }
    }
    
    function setPrices(uint256 newEthPrice, uint256 newErc20Price) external onlyOwner {
        ethPrice = newEthPrice;
        erc20Price = newErc20Price;
        emit PriceUpdated(newEthPrice, newErc20Price);
    }
    
    function setPaymentToken(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        paymentToken = IERC20(tokenAddress);
        emit PaymentTokenChanged(tokenAddress);
    }
    
    function setPaymentMethod(bool _useERC20) external onlyOwner {
        if (_useERC20) {
            require(paymentToken != IERC20(address(0)), "Set token first");
        }
        useERC20 = _useERC20;
        emit PaymentMethodSwitched(_useERC20);
    }
    
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseURI = newBaseURI;
    }
    
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        return string(abi.encodePacked(baseURI, tokenId.toString(), ".json"));
    }
    
    function getRemainingSupply() external view returns (uint256) {
        return MAX_SUPPLY - _nextTokenId;
    }
    
    function totalSupply() external view returns (uint256) {
        return _nextTokenId;
    }
    
    function withdrawETH() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No ETH to withdraw");
        payable(owner()).transfer(balance);
    }
    
    function withdrawERC20(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        token.transfer(owner(), balance);
    }
    
    receive() external payable {}
}
