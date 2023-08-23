import { ethers } from "ethers";
import rsvABI from "./rsvabi.json";
import susdABI from "./susdabi.json";

const rsvcontract = "0xba1f546071d9d7E2388d420AC1091ce58F661Efc";
const susdcontract = "0x480724B920B486af30610b5Ed6456B0113951F43";
const rpc = "https://rpc.ankr.com/polygon_mumbai";
const provider = new ethers.providers.JsonRpcProvider(rpc);
const key = "";
const wallet = new ethers.Wallet(key, provider);
const reserves = new ethers.Contract(rsvcontract, rsvABI, wallet);
const susd = new ethers.Contract(susdcontract, susdABI, wallet);

export async function getReserves() {
  const rsvcount = Number((await reserves.reserveLength()).toString());
  const susdformat = (await susd.totalSupply()).toString();
  const susdsupply = ethers.utils.formatEther(susdformat);
  let i = 0;
  let rsvamounts = [];
  for (i; i < rsvcount; i++) {
    const balance = await reserves.rsvVault(i);
    const getbalance = balance.amount.toString();
    let formatbalance = ethers.utils.formatEther(getbalance);
    rsvamounts.push(formatbalance);
  }
  return { rsvamounts, susdsupply };
}
