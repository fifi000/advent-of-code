import { readFileSync } from 'fs';

const content = readFileSync('./2024/day13/input copy.txt', 'utf8');

const elements = content.replaceAll('\r', '').split('\n\n');

elements.forEach(equation => {
    const lines = equation.split('\n');
    
    // Xs
    console.log(lines[0].match(/X\+(\d+)/)[1]);
    console.log(lines[1].match(/X\+(\d+)/)[1]);
    console.log(lines[2].match(/X=(\d+)/)[1]);
    
    // Ys
    console.log(lines[0].match(/Y\+(\d+)/)[1]);
    console.log(lines[1].match(/Y\+(\d+)/)[1]);
    console.log(lines[2].match(/Y=(\d+)/)[1]);
});

