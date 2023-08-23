const ethpricedb = require("./ethpricedb.json");
const susdpricedb = require("./susdpricedb.json");
const fs = require("fs").promises;

const readDb = async (token) => {
  if (token == "eth") {
    const output = await fs.readFile("ethpricedb.json", function (err, data) {
      if (err) throw err;
      return Buffer.from(data);
    });
    const pricedb = JSON.parse(output);
    return pricedb;
  } else {
    const output = await fs.readFile("susdpricedb.json", function (err, data) {
      if (err) throw err;
      return Buffer.from(data);
    });
    const pricedb = JSON.parse(output);
    return pricedb;
  }
};

const writeDb = async (price, time, lastentry, token) => {
  let entry = {
    updateprice: price,
    timedate: time,
    entry: lastentry + 1,
  };
  if (token == "eth") {
    ethpricedb.push(entry);
    let output = await fs.writeFile(
      "ethpricedb.json",
      JSON.stringify(ethpricedb),
      (err) => {
        if (err) throw err;
        return "Done";
      }
    );
    return output;
  } else {
    susdpricedb.push(entry);
    let output = await fs.writeFile(
      "susdpricedb.json",
      JSON.stringify(susdpricedb),
      (err) => {
        if (err) throw err;
        return "Done";
      }
    );
    return output;
  }
};

module.exports = { readDb, writeDb };
