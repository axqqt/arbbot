"use client"

import { useState, useEffect } from 'react';
import { ethers } from 'ethers';
import Web3Modal from 'web3modal';
import contractABI from '../../contracts/FlashloanArbitrageABI.json'; // Import ABI

const contractAddress = '0xYourContractAddressHere'; // Update with your contract address

export default function Home() {
  const [provider, setProvider] = useState(null);
  const [signer, setSigner] = useState(null);
  const [contract, setContract] = useState(null);
  const [loanAmount, setLoanAmount] = useState('');
  const [connectedWallet, setConnectedWallet] = useState(null);

  // Initialize Web3Modal on load
  useEffect(() => {
    const initWeb3Modal = async () => {
      const web3Modal = new Web3Modal();
      const instance = await web3Modal.connect();
      const provider = new ethers.providers.Web3Provider(instance);
      const signer = provider.getSigner();
      
      setProvider(provider);
      setSigner(signer);
      setConnectedWallet(await signer.getAddress());

      const contractInstance = new ethers.Contract(contractAddress, contractABI, signer);
      setContract(contractInstance);
    };

    initWeb3Modal();
  }, []);

  // Handle arbitrage execution
  const executeArbitrage = async () => {
    if (!contract || !loanAmount) return;

    try {
      const tx = await contract.executeArbitrage(
        '0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0', // Example: asset (MATIC address on mainnet)
        ethers.utils.parseEther(loanAmount) // Convert to wei
      );
      await tx.wait();
      alert('Arbitrage executed successfully!');
    } catch (err) {
      console.error('Error executing arbitrage:', err);
      alert('Error executing arbitrage.');
    }
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center bg-gray-100">
      <h1 className="text-4xl font-bold mb-4">Flashloan Arbitrage</h1>

      {connectedWallet ? (
        <div className="bg-white p-6 rounded shadow-lg w-96">
          <p className="mb-4">Connected Wallet: {connectedWallet}</p>
          <div className="mb-4">
            <label className="block mb-2 text-sm font-bold">Loan Amount (ETH):</label>
            <input
              type="text"
              value={loanAmount}
              onChange={(e) => setLoanAmount(e.target.value)}
              className="w-full px-4 py-2 border border-gray-300 rounded"
              placeholder="Enter loan amount"
            />
          </div>
          <button
            onClick={executeArbitrage}
            className="w-full bg-blue-500 text-white py-2 rounded hover:bg-blue-600 transition duration-200"
          >
            Execute Arbitrage
          </button>
        </div>
      ) : (
        <p className="text-lg">Connecting to wallet...</p>
      )}
    </div>
  );
}
