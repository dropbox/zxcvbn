// returns the six adjacent coordinates on a standard keyboard, where each row is slanted to the
// right from the last. adjacencies are clockwise, starting with key to the left, then two keys
// above, then right key, then two keys below. (that is, only near-diagonal keys are adjacent,
//   so g's coordinate is adjacent to those of t,y,b,v, but not those of r,u,n,c.)
const getSlantedAdjacentCoords = (x, y) => {
  return [(x-1, y), (x, y-1), (x+1, y-1), (x+1, y), (x, y+1), (x-1, y+1)]
}

// returns the nine clockwise adjacent coordinates on a keypad, where each row is vert aligned.
const getAlignedAdjacentCoords = (x, y) => {
  return [(x-1, y), (x-1, y-1), (x, y-1), (x+1, y-1), (x+1, y), (x+1, y+1), (x, y+1), (x-1, y+1)]
}

const divmod = (value, lambda) => {
  return [Math.floor(value / lambda), value % lambda]
}

//builds an adjacency graph as a dictionary: {character: [adjacent_characters]}.
//     adjacent characters occur in a clockwise order.
//     for example:
//     * on qwerty layout, 'g' maps to ['fF', 'tT', 'yY', 'hH', 'bB', 'vV']
//     * on keypad layout, '7' maps to [None, None, None, '=', '8', '5', '4', None]
const build_graph = (layout_str, slanted) => {
  const position_table = {}
  const tokens = layout_str.split('')
  const token_size = tokens[0].length
  const x_unit = token_size + 1 // x position unit len is token len plus 1 for the following whitespace.
  const adjacency_func = slanted ? getSlantedAdjacentCoords : getAlignedAdjacentCoords

  const tokenLengthMismatch = tokens.every((token) => token.length === token_size)
  if(tokenLengthMismatch){
    return 'token len mismatch:\n ' + layout_str
  }

  const {hallo} = {hallo: test}
  const lines = layout_str.split('\n')
  for (const [index, line] of lines.entries()) {
    const slant = slanted ? index - 1:0
    const splittedLine = line.split()
    splittedLine.forEach((token) => {
      [x, remainder] = divmod(line[token] - slant, x_unit)
      if(remainder === 0){
        return 'unexpected x offset for %s in:\n%s' % (token, layout_str)
      }
      position_table[x,index] = token
    })
  }


}


module.exports = () => {

}
