import vibe.d;
import std.stdio;
import std.string;
import std.algorithm;
import core.stdc.stdlib;
import std.format : format;
import core.exception;
import std.conv;
import std.exception;
import std.random;

class Board {
    const int rows = 15;
    const int columns = 15;
	static const int nWin = 5; //количество крестиков или ноликов подряд, необходимое для выигрыша
    char[rows][columns] board;
	char[rows][columns] nearcell;
    char currentPlayer = 'X';
	char servMark;
	char cMark;
	this(){
		for (int i = 0; i<this.rows; i++)
            for (int k = 0; k<this.columns; k++)
                this.board[i][k] = '_';
	}
	
    void printBoard() @safe {
        write("  ");
        char colL = 'A'; //координата столбца
        for (int i = 0; i < columns; i++) {
            write(" ");
            write(colL);
            colL++;
        }
        write("\n");
		write("  ");
		for(int row = 0; row < this.columns; row++)
		{	
			write(" _");
		}
		writeln();
        char rowL = 'a'; //координата ряда
		for (int i = 0; i < rows; i++)
		{
			write(rowL);
			rowL++;
			write(" ");
			for (int k = 0; k < columns; k++)
			{
			write(char(179));
			write(board[i][k]);
			}
			writeln(char(179));
		}
	}
	
bool checkPosition(int row, int col) //проверяем выход за пределы массива
	{
		if (row >= rows || row < 0 || col >= columns || col < 0)
			return false;
		if (board[row][col] == '_')
			return true;
		else
			return false;
	}

Coordinates[] EmptyCellsAround(Coordinates c) //ищет пустые клетки вокруг последнего хода
{
	int rcoord = c.x;
	int ccoord = c.y;
	//writeln("rcoord ", rcoord,  " ccoord ", ccoord);
	int nr, nc;
	Coordinates[] emptyCells = [];
	Dir[] dirlist = [
        Dir(1, 1), Dir(1, 0), Dir(1, -1), Dir(0, -1), Dir(-1, -1),
		Dir(-1, 0), Dir(-1, 1), Dir(0, 1) ];
	foreach (Dir d; dirlist) 
	{
		nr = rcoord+d.i;
		nc = ccoord+d.j;
		if ((nr == -1)||(nc == -1)||(nr == 15)||(nc == 15))
			{
				writeln("borders violated");
			}
		else
		{
		nearcell[nr][nc] = this.board[rcoord+d.i][ccoord+d.j];
		if (checkPosition(nr, nc)) 
			{
				if ((nearcell[nr][nc] != 'X')&&(nearcell[nr][nc] != 'O'))
				{
					emptyCells ~= [Coordinates(nr,nc)];
					writeln("do we get here in loop");
				}
				else 
				{
				writeln("we won't reach this point");
				}
			}
		else writeln("not empty cell after if");
		}
	}
	return emptyCells;
}

Coordinates makeCompMove(Coordinates enemy, bool first) //компьютер делает ход
	{		bool firstMove = first;
			Coordinates centerMark = Coordinates(to!int(rows / 2), to!int(columns / 2));
			int cmrow = centerMark.x;
			int cmcol = centerMark.y;
			Coordinates move;
			if ((firstMove) && (this.board[cmrow][cmcol] == '_'))//это начало игры, и поле пустое, так что ставим в середину
				{
					firstMove = false;
					move = centerMark;
				}
			else
			{
				Coordinates[] cellsAround = EmptyCellsAround(enemy);
				if (!cellsAround.empty()) //если вокруг клетки есть пустые клетки, выбираем из списка случайную клетку и ходим туда
					{
						auto chosenMove = cellsAround[uniform(0, $)];
						//auto rnd = rndGen;
						//auto chosenMove = cellsAround.choice(rnd);
						move = Coordinates(chosenMove.x, chosenMove.y);
					}
				else //если вокруг клетки, в которую противник сделал ход, нет свободных клеток => список пуст
					{
						auto chosenMove = possibleMovesList()[uniform(0, $)];
						move = Coordinates(chosenMove.x, chosenMove.y);
					}
			}
				return move;
	}

Coordinates[] possibleMovesList() //возвращает все возможные ходы
	{
		Coordinates[] possibleMoves = [];
		for (int i = 0; i< rows; i++) 
		{
			for (int k = 0; k< columns; k++)
				{
					if ((this.board[i][k] != 'X')&&(this.board[i][k] != 'O'))
					possibleMoves ~= [Coordinates(i,k)];
				}
		}
		return possibleMoves;
	}
	
bool updateBoard  (int r, int c) { //обновляем игровое поле
		if (checkPosition(r, c))
			board[r][c] = currentPlayer;
		else
			return false;
		return true;
	}
void changeCurrentPlayer() @safe{ //ход переходит следующему игроку
		if(currentPlayer == 'X')
			currentPlayer = 'O';
		else
			currentPlayer = 'X';
	}


bool checkWinner(int r, int c){ //проверка на победу - 5 подряд
	int i,j;
	
		//пять в ряд
		int playerCount = 0;
		for (i = c-(nWin-1); i <= c+(nWin-1); i++) 
		{
    	if (i < 0 || i > columns-1) continue;
    	if (this.board[r][i] == this.currentPlayer) 
    	{
    	    playerCount++;
		}
		else playerCount=0;
		if( playerCount >= nWin ){
			return true;
			}
		}
		
		//пять в столбец
		playerCount = 0;
		 for (i= r-(nWin-1); i <= r+(nWin-1); i++) 
		{
        if (i < 0 || i > rows-1) continue;
    	if (this.board[i][c] == this.currentPlayer) 
    	{
    	    playerCount++;
		}
		else playerCount=0;
		if( playerCount >= nWin ){
			return true;
			}
		}
		
		
		
		//пять подряд по главной диагоняли (слева направо)
		playerCount = 0;
		 for (i = c-(nWin-1), j = r-(nWin-1); i <= c+(nWin-1) && j <= r+(nWin-1); i++, j++) 
		{
	    if (i < 0 || i > columns - 1 || j < 0 || j > rows - 1) continue; 
    	if (this.board[j][i] == this.currentPlayer) 
    	{
    	    playerCount++;
			}
			else playerCount=0;
		if( playerCount >= nWin ){
			return true;
			}
		}
			
				
		//пять подряд по второй диагоняли (справа налево)
		playerCount = 0;
		 for (i = c-(nWin-1), j = r+(nWin-1); i <= c+(nWin-1) && j>=0; i++, j--) 
		{
        if (i < 0 || i > columns - 1 || j < 0 || j > rows - 1) continue;
    	if (this.board[j][i] == this.currentPlayer) 
    	{
    	    playerCount++;
		
		}
		else playerCount=0;
		if( playerCount >= nWin ){
			return true;
			}
		}
		 
        return false;
	}
		
	bool checkDraw() //проверка на ничью
	{
		for (int i = 0; i < rows; i++)
		{
			for (int j = 0; j < columns; j++)
			{
				if(board[i][j] == '_') //если остались незаполненные клетки
					return true;
			}
		}
		return false;
	}
};
	
	struct Coordinates
{
	int x;
	int y;
}

struct Dir
{
	int i;
	int j;
}

	char changeMark(char m) @safe //меняет крестик на нолик и наоборот
	{
	if(m == 'O')
		return 'X';
	return 'O';
	}

	int rowValue(char row){ //превращаем символы в инты
	return cast(int)(row - 97);
	}
	int colValue(char column){
	return cast(int)(column - 65);
	}
	
	
	char rowSym(int row){ //превращаем инты в символы
	return cast(char)(row + 97);
	}
	char colSym(int column){
	return cast(char)(column + 65);
	}
	
string writeInput(Coordinates coor) {
    char x = to!char(coor.x + 'a');
    char y = to!char(coor.y + 'A');
    string s = "";
    s ~= x;
    s ~= y;
    return s;
}
void main()
{
	listenTCP(7000,(conn) {
		writeln("server is running");
		Board board = new Board();
		board.printBoard();
		char row, column; char enemyRow, enemyColumn;
		int row1, column1;
		bool winner = false; // игра не окончена
		bool control = true; //отмечает правильность ввода
		bool draw = false; //маркирует ничью
		bool firstMove = true;
		char rr, cc;
		Coordinates enemyCoord;
        string moveInput = "";
		conn.write("O\r\n");
		board.servMark = 'X';
		board.cMark = changeMark(board.servMark);
		writeln("You: ", board.servMark);
		writeln("Client: ", board.cMark);
		while(!winner) { //пока игра не окончена
			writeln();
			if(board.currentPlayer == board.servMark) 
			/* {
				do
				{
					write("Server (", board.servMark, "), enter row and column (ex: aB): ");
					readf("%s\n", moveInput);
					if (moveInput.length==2){
						row=moveInput[0];
						column=moveInput[1];
						control = board.updateBoard(rowValue(row), colValue(column));
					}
					else {
					control=false;
					}
					if (control == false) {
					write("\n");
					writeln("Please, write the empty cell coordinates correctly. Only letters allowed (ex: aB): ");
					}
				} while (!control); //пока не введут правильно
				moveInput = moveInput ~ "\r\n";
				conn.write(moveInput);
				winner = board.checkWinner(rowValue(row), colValue(column));
				draw = board.checkDraw();
				if (!draw){
					board.printBoard();
					write("\n\nIt's draw!");
				break;
				}
				if(!winner) board.changeCurrentPlayer();
				system("cls");
				board.printBoard();
				
			} */
			{
					write("Server (", board.servMark, "), enter row and column (ex: aB): ");
					enemyCoord.x = rowValue(enemyRow);
					enemyCoord.y = colValue(enemyColumn);
					writeln("enemyCoords ", enemyCoord.x, " and ", enemyCoord.y);
					Coordinates chosenAIMove = board.makeCompMove(enemyCoord, firstMove);
						row1=chosenAIMove.x;
						column1=chosenAIMove.y;
						writeln("chosenAIMove ", chosenAIMove.x, " and ", chosenAIMove.y);
						board.updateBoard(row1, column1);
						moveInput = writeInput(chosenAIMove) ~ "\r\n";
						writeln("moveinput ", moveInput);
				conn.write(moveInput);
				winner = board.checkWinner(row1, column1);
				draw = board.checkDraw();
				if (!draw){
					board.printBoard();
					write("\n\nIt's draw!");
				break;
				}
				if(!winner) board.changeCurrentPlayer();
				system("cls");
				board.printBoard();
				
			}
			else {
				write("It's client's (", board.cMark, ") turn, please, wait\n");
				string enemyMoveInput = cast(string)conn.readLine();
				writeln("got it ", enemyMoveInput);
				enemyRow=enemyMoveInput[0];
				enemyColumn=enemyMoveInput[1];
				board.updateBoard(rowValue(enemyRow), colValue(enemyColumn));
				winner = board.checkWinner(rowValue(enemyRow), colValue(enemyColumn));
				if(!winner) board.changeCurrentPlayer();
				system("cls");
				board.printBoard();
			}
		}
		writeln("The winner is ", board.currentPlayer, " !");
    });
    runApplication();
}
