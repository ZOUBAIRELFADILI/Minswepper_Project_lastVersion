import 'dart:math';

import 'package:flutter/material.dart';
//import 'package:minesweeper/core/theme/app_color.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key}); //Constructor // état mutable

  @override
  State<HomePage> createState() => _HomePageState();
} //State for the HomePage Widget

class _HomePageState extends State<HomePage> {
  int rows = 12;
  int columns = 8;
  int totalMines = 10;
  List<List<Cell>> grid = [];

  int flagCount = 10;
  bool gameOver = false;

// Helper function to calculate border radius based on the cell's position
  BorderRadius _calculateBorderRadius(int row, int col) {
    bool isTopEdge = row == 0;
    bool isBottomEdge = row == rows - 1;
    bool isLeftEdge = col == 0;
    bool isRightEdge = col == columns - 1;

    if (isTopEdge && isLeftEdge) {
      return BorderRadius.only(topLeft: Radius.circular(0));
    } else if (isTopEdge && isRightEdge) {
      return BorderRadius.only(topRight: Radius.circular(0));
    } else if (isBottomEdge && isLeftEdge) {
      return BorderRadius.only(bottomLeft: Radius.circular(0));
    } else if (isBottomEdge && isRightEdge) {
      return BorderRadius.only(bottomRight: Radius.circular(0));
    } else if (isTopEdge) {
      return BorderRadius.vertical(top: Radius.circular(0));
    } else if (isBottomEdge) {
      return BorderRadius.vertical(bottom: Radius.circular(0));
    } else if (isLeftEdge) {
      return BorderRadius.horizontal(left: Radius.circular(0));
    } else if (isRightEdge) {
      return BorderRadius.horizontal(right: Radius.circular(0));
    } else {
      return BorderRadius.zero;
    }
  }

// Helper function to calculate cell color based on neighbors
  Color _calculateCellColor(int row, int col) {
    bool isEvenRow = row % 2 == 0;
    bool isEvenCol = col % 2 == 0;

    if (isEvenRow) {
      return isEvenCol ? Color(0xFFAAD751) : Color(0xFFA2D149);
    } else {
      return isEvenCol ? Color(0xFFA2D149) : Color(0xFFAAD751);
    }
  }

  Color _calculateOpenedCellColor(int row, int col) {
    bool isEvenRow = row % 2 == 0;
    bool isEvenCol = col % 2 == 0;

    if (isEvenRow) {
      return isEvenCol ? Color(0xFFE5C29F) : Color(0xFFD7B899);
    } else {
      return isEvenCol ? Color(0xFFD7B899) : Color(0xFFE5C29F);
    }
  }

  @override
  void initState() {
    //Initialize the game grid wehn the widget is first created
    super.initState();
    _intializeGrid();
  }

  //Initializes the game grid with empty cells, places mines randomly, and calculates the number of adjacent mines for each cell
  void _intializeGrid() {
    // Initialize grid with empty cells
    grid = List.generate(
      rows,
      (row) => List.generate(
        columns,
        (col) => Cell(
          row: row,
          col: col,
        ),
      ),
    );

    
    final random = Random();
    int count = 0;
    while (count < totalMines) {
      int randomRow = random.nextInt(rows);
      int randomCol = random.nextInt(columns);
      if (!grid[randomRow][randomCol].hasMine) {
        grid[randomRow][randomCol].hasMine = true;
        count++;
      }
    }

    //calculer number de bombe dans les cell adjacant
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < columns; col++) {
        /// has mines no nothing
        if (grid[row][col].hasMine) continue;

        int adjacentMines = 0;
        for (final dir in directions) {
          int newRow = row + dir.dy.toInt();
          int newCol = col + dir.dx.toInt();

          if (_isValidCell(newRow, newCol) && grid[newRow][newCol].hasMine) {
            adjacentMines++;
          }
        }

        /// adjacentMines indicate the number of mines
        /// in its sourounding / neighbour
        grid[row][col].adjacentMines = adjacentMines;
      }
    }
  }

  /// [-1,-1] [-1,0] [-1,1]
  ///
  /// [0,-1] [cell] [0,1]
  ///
  /// [1,-1] [1,0] [1,1]
  final directions = [
    //List of Offeset objects representing directions (neighbors) around a cell
    const Offset(-1, -1),
    const Offset(-1, 0),
    const Offset(-1, 1),
    const Offset(0, -1),
    const Offset(0, 1),
    const Offset(1, -1),
    const Offset(1, 0),
    const Offset(1, 1),
  ];

  //  Checkes if the given row and column indices are valid within the grid
  bool _isValidCell(int row, int col) {
    return row >= 0 && row < rows && col >= 0 && col < columns;
  }

// Handles the tap on a cell, revealing mines or opening adjacent cells
  void _handleCellTap(Cell cell) {
    if (gameOver || cell.isOpen || cell.isFlagged) return;

    setState(() {
      cell.isOpen = true;

      if (cell.hasMine) {
        // Game over - show all mines
        gameOver = true;
        for (final row in grid) {
          for (final cell in row) {
            if (cell.hasMine) {
              cell.isOpen = true;
            }
          }
        }
        showSnackBar(context, message: "Game Over !!!!");
      } else if (_checkForWin()) {
        // Game won - show all cells
        gameOver = true;

        for (final row in grid) {
          for (final cell in row) {
            cell.isOpen = true;
          }
        }
        showSnackBar(context, message: "Congratulation :D");
      } else if (cell.adjacentMines == 0) {
        // Open adjacent cells if there are no mines nearby
        _openAdjacentCells(cell.row, cell.col);
      }
    });
  }

  bool _checkForWin() {
    for (final row in grid) {
      for (final cell in row) {
        // chek if we still has un open cell
        // that are not mines
        // if we has on immidiate return
        // indicate that the game still not over
        if (!cell.hasMine && !cell.isOpen) {
          return false;
        }
      }
    }

    return true;
  }

  
  void _openAdjacentCells(int row, int col) {
    /// open neigbour cells
    for (final dir in directions) {
      int newRow = row + dir.dy.toInt();
      int newCol = col + dir.dx.toInt();

      /// if not open and not mines
      if (_isValidCell(newRow, newCol) &&
          !grid[newRow][newCol].hasMine &&
          !grid[newRow][newCol].isOpen) {
        setState(() {
          // open the cell
          grid[newRow][newCol].isOpen = true;
          // and check if its has no mines in suroinding
          /// open adjacentCells in that position

          /// this process will get loop untul it find a mines
          if (grid[newRow][newCol].adjacentMines == 0) {
            _openAdjacentCells(newRow, newCol);
          }
        });
      }
    }

    if (gameOver) return;

    if (_checkForWin()) {
      gameOver = true;
      for (final row in grid) {
        for (final cell in row) {
          if (cell.hasMine) {
            cell.isOpen = true;
          }
        }
      }
      showSnackBar(context, message: "Congratulation :D");
    }
  }

//Handles a long press on a cell, toggling its flag status
  void _handleCellLongPress(Cell cell) {
    if (cell.isOpen) return;
    if (flagCount <= 0 && !cell.isFlagged) return;

    setState(() {
      cell.isFlagged = !cell.isFlagged;

      if (cell.isFlagged) {
        flagCount--;
      } else {
        flagCount++;
      }
    });
  }

// Resets the game state, reinitializing the grid
  void _reset() {
    setState(() {
      grid = [];
      gameOver = false;
      flagCount = 10;
    });

    _intializeGrid();
  }

  void showSnackBar(BuildContext context, {required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

//Builds the UI for minesweeper gane using a Scaffold, AppBar, ListView , GridView
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Minesweeper',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: Container(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    children: [
                      Text(
                        "💣",
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(
                        flagCount.toString(),
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(
                      Icons.restart_alt,
                    ),
                    label: const Text("Reset"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFAAD751),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  )
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Color(0xFF4D3F32),
                  width: 16,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2), // Shadow color
                    spreadRadius: 2, // Spread radius
                    blurRadius: 4, // Blur radius
                    offset: Offset(0, 2), // Offset in the x, y directions
                  ),
                ],
              ),
              child: GridView.builder(
                padding: EdgeInsets.all(0),
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: rows * columns,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 0,
                ),
                itemBuilder: (context, index) {
                  final int row = index ~/ columns;
                  final int col = index % columns;
                  final cell = grid[row][col];

                  Color cellColor;
                  Color textColor;

                  // Set colors based on the cell state
                  if (!cell.isOpen) {
                    // Alternating colors based on neighbors
                    cellColor = _calculateCellColor(row, col);
                    textColor = Colors.black;
                  } else {
                    // Set background color for opened cells
                    cellColor = _calculateOpenedCellColor(
                        row, col); // Dark color for opened cell background

                    // Set text color for opened cells based on content
                    textColor = cell.hasMine
                        ? Colors.black
                        : _getNumberColor(cell.adjacentMines);
                  }

                  return GestureDetector(
                    onTap: () => _handleCellTap(cell),
                    onLongPress: () => _handleCellLongPress(cell),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: _calculateBorderRadius(row, col),
                        color: cellColor,
                        border: Border.all(
                          color: Color(0xFF99A655),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cell.isOpen
                              ? cell.hasMine
                                  ? '💣'
                                  : cell.adjacentMines == 0
                                      ? ''
                                      : '${cell.adjacentMines}'
                              : cell.isFlagged
                                  ? '🚩'
                                  : '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: cell.isFlagged ? 24 : 18,
                            color: textColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

// Helper function to get number color based on the number of adjacent mines
  Color _getNumberColor(int adjacentMines) {
    switch (adjacentMines) {
      case 1:
        return Color(0xFF0B6DB5); // Blue for 1
      case 2:
        return Color(0xFF478526); // Green for 2
      case 3:
        return Colors.red; // Red for 3
      case 4:
        return Color(0xFFA40000); // Darker Red for 4
      default:
        return Colors.transparent; // No text color for other cases
    }
  }
}

class Cell {
  final int row;
  final int col;

  bool hasMine;
  bool isOpen;
  bool isFlagged;
  int adjacentMines;
// Constructor for the Cell class, representing a cell in the Minesweeper game
  Cell({
    required this.row,
    required this.col,
    this.isFlagged = false,
    this.hasMine = false,
    this.isOpen = false,
    this.adjacentMines = 0,
  });
}
