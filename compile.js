"use strict";
var __assign = (this && this.__assign) || function () {
    __assign = Object.assign || function(t) {
        for (var s, i = 1, n = arguments.length; i < n; i++) {
            s = arguments[i];
            for (var p in s) if (Object.prototype.hasOwnProperty.call(s, p))
                t[p] = s[p];
        }
        return t;
    };
    return __assign.apply(this, arguments);
};
var __spreadArrays = (this && this.__spreadArrays) || function () {
    for (var s = 0, i = 0, il = arguments.length; i < il; i++) s += arguments[i].length;
    for (var r = Array(s), k = 0, i = 0; i < il; i++)
        for (var a = arguments[i], j = 0, jl = a.length; j < jl; j++, k++)
            r[k] = a[j];
    return r;
};
exports.__esModule = true;
var path_1 = require("path");
var fs_extra_1 = require("fs-extra");
var child_process_1 = require("child_process");
var ethers_1 = require("ethers");
var solc = require('solc');
var filesToIgnore = { '.DS_Store': true };
var buildFolderPath = path_1.resolve(__dirname, 'build', 'artifacts');
var lastSourceHashFilePath = path_1.resolve(__dirname, 'sst-config.json');
var sources = {};
function addSourcesFromThisDirectory(sourceFolderPath, relativePathArray) {
    if (relativePathArray === void 0) { relativePathArray = []; }
    fs_extra_1.readdirSync(path_1.resolve.apply(void 0, __spreadArrays([sourceFolderPath], relativePathArray))).forEach(function (childName) {
        var _a;
        if (filesToIgnore[childName])
            return;
        var childPathArray = __spreadArrays(relativePathArray, [childName]);
        if (fs_extra_1.lstatSync(path_1.resolve.apply(void 0, __spreadArrays([sourceFolderPath], childPathArray))).isDirectory()) {
            addSourcesFromThisDirectory(sourceFolderPath, childPathArray);
        }
        else {
            var fileExtension = childName.split('.').slice(-1)[0];
            if (['solidity', 'sol', 'solid'].includes(fileExtension)) {
                // console.log(childPathArray.join('/'));
                sources = __assign(__assign({}, sources), (_a = {}, _a[childPathArray.join('/')] = {
                    content: fs_extra_1.readFileSync(path_1.resolve.apply(void 0, __spreadArrays([sourceFolderPath], childPathArray)), 'utf8')
                }, _a));
            }
        }
    });
}
// includes solidity files from contracts dir
addSourcesFromThisDirectory(path_1.resolve(__dirname, 'contracts'));
// includes solidity files in node_module
// all dependencies are not included since they might not be compatible with latest versions
// addSourcesFromThisDirectory(resolve(__dirname, 'node_modules'), [
//   '@openzeppelin',
// ]);
// console.log({sources});
function convertToHex(inputString) {
    var hex = '';
    for (var i = 0; i < inputString.length; i++) {
        hex += '' + inputString.charCodeAt(i).toString(16);
    }
    return hex;
}
var sourceHash = ethers_1.ethers.utils.sha256('0x' + convertToHex(JSON.stringify(sources)));
console.log('\n'.repeat(process.stdout.rows));
if (fs_extra_1.existsSync(buildFolderPath) &&
    fs_extra_1.existsSync(lastSourceHashFilePath) &&
    JSON.parse(fs_extra_1.readFileSync(lastSourceHashFilePath, 'utf8')).sourceHash ===
        sourceHash) {
    console.log('No changes in .sol files detected... \nSkiping compile script...\n');
}
else {
    // write the source hash there at the end of
    // console.log(lastSourceHash,sourceHash);
    var input = {
        language: 'Solidity',
        sources: sources,
        settings: {
            outputSelection: {
                '*': {
                    '*': ['*']
                }
            }
        }
    };
    console.log('Compiling contracts...');
    var output = JSON.parse(solc.compile(JSON.stringify(input)));
    console.log('Contracts compiled succcessfully!');
    var shouldBuild = true;
    if (output.errors) {
        // console.error(output.errors);
        for (var _i = 0, _a = output.errors; _i < _a.length; _i++) {
            var error = _a[_i];
            console.log('-'.repeat(process.stdout.columns));
            console.group(error.severity.toUpperCase());
            console.log(error.formattedMessage);
            console.groupEnd();
        }
        if (Object.values(output.errors).length)
            console.log('-'.repeat(process.stdout.columns));
        // throw '\nError in compilation please check the contract\n';
        for (var _b = 0, _c = output.errors; _b < _c.length; _b++) {
            var error = _c[_b];
            if (error.severity === 'error') {
                shouldBuild = false;
                throw 'Error found\n';
                break;
            }
        }
    }
    if (shouldBuild) {
        console.log('\nBuilding please wait...');
        fs_extra_1.removeSync(buildFolderPath);
        fs_extra_1.ensureDirSync(buildFolderPath);
        var i = 0;
        for (var contractFile in output.contracts) {
            for (var key in output.contracts[contractFile]) {
                //console.log(key, Object.keys(output.contracts[contractFile][key]));
                fs_extra_1.outputJsonSync(path_1.resolve(buildFolderPath, output.contracts[contractFile].length > 1
                    ? contractFile.split('.')[0] + "_" + key + ".json"
                    : contractFile.split('.')[0] + ".json"), output.contracts[contractFile][key]);
            }
            i++;
        }
        console.log('Build finished successfully!\n');
    }
    else {
        console.log('\nBuild failed\n');
    }
    fs_extra_1.outputJsonSync(path_1.resolve(lastSourceHashFilePath), { sourceHash: sourceHash });
    console.log('Running TypeChain...');
    child_process_1.execSync('npm run typechain');
    console.log('Type defination files generated successfully!\n');
}
