/*
plugin-goldenpond-vis.mjs - GoldenPond source-location support for vis('...') and vc('...')
*/
import { registerTranspilerPlugin } from './transpiler.mjs';

const goldenpondVis = {
  walk: (context) => ({
    enter: function (node) {
      if (!isGoldenPondLocationCall(node)) return;
      context.miniLocations ??= [];
      const { options, miniLocations } = context;
      const { emitMiniLocations } = options;
      const sourceArg = node.arguments[0];
      const offset = sourceArg.start + quoteOffset(sourceArg.raw);
      const source = String(sourceArg.value);
      const locations = node.callee.name === 'vis'
        ? getGoldenPondRhythmLocations(source, offset)
        : getGoldenPondChordLocations(source, offset);
      if (emitMiniLocations) {
        miniLocations.push(...locations);
      }
      if (!hasInjectedOffset(node)) {
        node.arguments.push({ type: 'Literal', value: offset, raw: String(offset) });
      }
      this.skip();
      return true;
    },
  }),
};

function isGoldenPondLocationCall(node) {
  return node.type === 'CallExpression'
    && node.callee?.type === 'Identifier'
    && (node.callee.name === 'vis' || node.callee.name === 'vc')
    && node.arguments.length >= 1
    && node.arguments[0]?.type === 'Literal'
    && typeof node.arguments[0].value === 'string';
}

function hasInjectedOffset(node) {
  return node.arguments.length >= 2
    && node.arguments[1]?.type === 'Literal'
    && typeof node.arguments[1].value === 'number';
}

function quoteOffset(raw) {
  return raw && (raw[0] === "'" || raw[0] === '"') ? 1 : 0;
}

function trimSource(input, offset) {
  const trimmedStart = input.search(/\S/);
  if (trimmedStart < 0) return null;
  let trimmedEnd = input.length;
  while (trimmedEnd > trimmedStart && /\s/.test(input[trimmedEnd - 1])) trimmedEnd--;
  return { text: input.slice(trimmedStart, trimmedEnd), base: offset + trimmedStart };
}

function getGoldenPondRhythmLocations(input, offset) {
  const trimmed = trimSource(input, offset);
  if (!trimmed) return [];
  return getExplicitLocations(trimmed.text, trimmed.base) ?? getGeneratedLocations(trimmed.text, trimmed.base) ?? [];
}

function getExplicitLocations(text, base) {
  const match = /^(\S+)\s+[0-9]+(?:\/[0-9]+)?$/.exec(text);
  if (!match) return null;
  const steps = match[1];
  const locs = [];
  for (let i = 0; i < steps.length; i++) {
    if (steps[i] !== '.') {
      locs.push([base + i, base + i + 1]);
    }
  }
  return locs;
}

function getGeneratedLocations(text, base) {
  const match = /^([0-9]+)[/%][0-9]+(?:\+[0-9]+)?\s+[><rcCbdtRpP0-9]\s+[0-9]+(?:\/[0-9]+)?$/.exec(text);
  if (!match) return null;
  return [[base, base + match[1].length]];
}

function getGoldenPondChordLocations(input, offset) {
  const locs = [];
  let i = 0;
  while (i < input.length) {
    const ch = input[i];
    if (isChordSeparator(ch)) {
      i++;
      continue;
    }
    if (ch === '&') {
      i++;
      continue;
    }
    if (ch === '!' || ch === '>' || ch === '<') {
      i = readDirective(input, i);
      continue;
    }
    const start = i;
    i = readChordAtom(input, i);
    if (i > start) {
      locs.push([offset + start, offset + i]);
    } else {
      i++;
    }
  }
  return locs;
}

function isChordSeparator(ch) {
  return ch === ',' || ch === '|' || /\s/.test(ch);
}

function readDirective(input, start) {
  let i = start + 1;
  while (i < input.length && !isChordSeparator(input[i]) && input[i] !== '&') i++;
  return i;
}

function readChordAtom(input, start) {
  let i = start;
  let depth = 0;
  while (i < input.length) {
    const ch = input[i];
    if (ch === '(' || ch === '[') depth++;
    if ((ch === ')' || ch === ']') && depth > 0) depth--;
    if (depth === 0 && (isChordSeparator(ch) || ch === '&')) break;
    i++;
  }
  return i;
}

registerTranspilerPlugin(goldenpondVis);
