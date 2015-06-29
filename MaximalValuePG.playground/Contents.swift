//: Playground - noun: a place where people can play

//
// http://codercareer.blogspot.com/2014/10/no-56-maximal-value-of-gifts.html
//
// No. 56 - Maximal Value of Gifts
//
// Question: A board has n*m cells, and there is a gift with some value (value is greater than 0)
// in every cell. You can get gifts starting from the top-left cell, and move right or down in 
// each step, and finally reach the cell at the bottom-right cell. What’s the maximal value of 
// gifts you can get from the board?
//
//
// board = [
//            [1,   10,   3,    8],
//            [12,   2,   9,    6],
//            [5,    7,   4,   11],
//            [3,    7,  16,    5]
//  ]
//
// For example, the maximal value of gift from the board above is 53, and the path is highlighted
// in red.
//

var str = "Hello, playground"

typealias Table = [[Int]]

typealias Cell = (row: Int, col: Int)

//
// Assumption: each row of the table contains the same number of columns
//
func == (left: Cell, right: Cell) -> Bool { return (left.row == right.row) && (left.col == right.col) }

// A board contains a table with gift holding cells at (row, col) locations.
//
class Board {
  var gifts: Table
  
  var rowCount: Int { return gifts.count }
  var colCount: Int { return (rowCount > 1) ? gifts[0].count : 0 }
  
  var maxPathLength: Int { return ((rowCount - 1) + (colCount - 1)) }
  
  init(gifts: Table) { self.gifts = gifts }
  
  // Use subscripts to access the gift at a location
  //
  subscript(cell: Cell) -> Int { return gifts[cell.row][cell.col] }
  
  func containsCell(cell: Cell) -> Bool {
    
    return      (cell.row >= 0) && (cell.row < rowCount)
            &&  (cell.col >= 0) && (cell.col < colCount)
  }
}

//--- Path
//

// A path starts at cell (0, 0) and contains a list of cells
//

// Overload + and += to help build paths incrementally
//
func += (inout left: Path, cell: Cell) { left.cells += [cell] }

func + (left: Path, cell: Cell) -> Path {
  var newPath = Path(path: left)
  newPath += cell
  
  return newPath
}

// Define an ordering among paths that have the same endpoint. A path yielding a larger gift
// is greater than the one with the smaller gift.
//
// Here are some key points of the algorithm used:
//  
//  - Start at the top left origin (0,0) and incrementally build paths leading to
//    the bottom right destination
//  
//  - Build paths by tacking on new cells to the end point (terminus) of a pre-existing path.
//    A new cell can only be one step to the right or one step towards the bottom of the terminus.
//
//  - Build a list of paths (PathList's) till you get paths that reach to the destination.
//
//  - At intermediate points during the path list build process, if you see two paths that have the
//    share the same end point, keep the one that yields the largest gift and discard the others.
//
func > (left: Path, right: Path) -> Bool {
  return left.hasSameTerminus(right) && (left.giftTotal > right.giftTotal)
}

class Path {
  var cells: [Cell]

  var board: Board

  var giftTotal: Int {
    return reduce(cells.map({ self.board[$0] }), 0) { $0 + $1 }
  }
  
  // Property that identifies the end point of a path
  //
  var lastCell: Cell { return cells.last! }
  
  var description: String {
    return reduce(self.cells, "") { $0 + "-\($1)" } + ": \(giftTotal)"
  }
  
  init(board: Board) {
    self.board = board
    
    self.cells = [(0, 0)]
  }
  
  convenience init(path: Path) {
    self.init(board: path.board)
    
    self.cells = path.cells
  }
  
  // Does the newPath have the same end point as this path?
  //
  func hasSameTerminus(newPath: Path) -> Bool { return (lastCell == newPath.lastCell) }
 
  // Build a new path by extending a pre-existing path to the right
  //
  class func extendRight(path: Path) ->  Path! {
    let lastCell = path.lastCell
  
    let nextRightCell = (lastCell.row, lastCell.col + 1)
    
    if (path.board.containsCell(nextRightCell)) {
      return (Path(path: path) + nextRightCell)
    }
    else { return path }
  }
  
  class func extendDown(path: Path) ->  Path! {
    let lastCell = path.lastCell
    
    let nextDownCell = (lastCell.row + 1, lastCell.col)

    if (path.board.containsCell(nextDownCell)) {
      return (Path(path: path) + nextDownCell)
    }
    else { return path }
  }
  
}

//--- PathList
//

// A path list contains a list of paths.
//
func += (inout left: PathList, path: Path) { left.paths += [path] }

func += (inout left: PathList, paths: [Path]) { left.paths += paths }

class PathList {
  var board: Board
  
  var paths: [Path]
  
  var description: String {
    
    return reduce(paths, "") { $0 + "\n--" + $1.description }
  }
  
  // Answer to: what is the maximum value of gifts yielded by a path in this path list?
  //
  var maxGiftTotal: Int {
    var giftTotals = paths.map( { $0.giftTotal })
    
    return maxElement(giftTotals)
  }

  init(board: Board) {
    self.board = board
    
    self.paths = []
  }
  
  subscript(index: Int) -> Path { return paths[index] }

  // Check if there is a pre-existing path with the same end point as the new path.
  //
  func sameTerminusPathIndex(newPath: Path) -> Int! {
    for (index, path) in enumerate(paths) {
      if (newPath.hasSameTerminus(path)) { return index }
    }
   
    return nil
  }
  
  // Build a list by extending each pre-existing path in the rightward and downward directions
  //
  class func elongatePaths(pathList: PathList) -> PathList {
    
    var allNewPaths = PathList(board: pathList.board)
    
    // one can only traverse to the right and down in the table.
    //
    allNewPaths.paths = reduce(pathList.paths, allNewPaths.paths) {
        $0 + [Path.extendRight($1), Path.extendDown($1)]
    }

    return allNewPaths
  }
  
  // Extend a list of pre-existing paths retaing for each (origin, destination) pair only the
  // path yielding the largest gift
  //
  class func extendAndImprove(pathList: PathList) -> PathList {
    
    let newPathList = elongatePaths(pathList)
    
    var nextPathList = PathList(board: pathList.board)
    
    for newPath in newPathList.paths {
      
      if let index = nextPathList.sameTerminusPathIndex(newPath) {
        if (newPath > nextPathList.paths[index]) { nextPathList.paths[index] = newPath }
      }
      else { nextPathList += newPath }
    }
    
    return nextPathList
  }
  
  class func extendMany(pathList: PathList, count: Int = 1) -> PathList {
    var newPathList = pathList
  
    for _ in 1...count { newPathList = PathList.extendAndImprove(newPathList) }
  
    return newPathList
  }
  
}

//--- main
//

func getMaxGiftTotal(board: Board) -> Int {
  
  var pl1 = PathList(board: board)
  
  pl1 += Path(board: board)
  
  var plEnd = PathList.extendMany(pl1, count: board.maxPathLength)
  
//  println("plEnd: \(plEnd.description)")  
//  println("\nplEnd: max gift =  \(plEnd.maxGiftTotal)")

  return plEnd.maxGiftTotal
}

//-----------------------
var board = Board(gifts: [
  [1,   10,   3,    8],
  [12,   2,   9,    6],
  [5,    7,   4,   11],
  [3,    7,  16,    5]
])

var expectedValue = 53
var actualValue = getMaxGiftTotal(board)

if (actualValue == expectedValue) { println("test_1: pass") }
else { println("test_1: fail: (expected, actual): (\(expectedValue), \(actualValue))") }
//---

board = Board(gifts: [
  [1,    2,     3],
  [4,    5,     6],
  [7,    8,     9]
])

expectedValue = 29
actualValue = getMaxGiftTotal(board)

if (actualValue == expectedValue) { println("test_2: pass") }
else { println("test_2: fail: (expected, actual): (\(expectedValue), \(actualValue))") }
//---

board = Board(gifts: [
  [1,    2,     3],
  [1,    4,     1]
  ])

expectedValue = 8
actualValue = getMaxGiftTotal(board)

if (actualValue == expectedValue) { println("test_3: pass") }
else { println("test_3: fail: (expected, actual): (\(expectedValue), \(actualValue))") }
//---











