import vibe.d;
import std.stdio;
import std.string;
import std.math;
import std.algorithm;
import std.array;
import std.conv;
import std.range;
import core.stdc.stdlib;
import std.format : format;
import core.exception;
import std.exception;


class Board {
    const uint rows = 15;
    const uint columns = 15;
	static const int nWin = 5;//количество крестиков или ноликов подряд, необходимое для выигрыша
    char[rows][columns] board;
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
	
void main() @trusted
{
	runTask({ {
	writeln("client is running");
	auto conn = connectTCP("127.0.0.1", 7000);
	Board board = new Board();
		board.printBoard();
		char row, column, enemyRow, enemyColumn;
		bool winner = false; // игра не окончена
		bool control = true; //отмечает правильность ввода
		bool draw = false; //маркирует ничью
        string moveInput = "";
		string chosenMark;
		chosenMark = cast(string)conn.readLine();
		char c = chosenMark[0];
		board.cMark = c;
		board.servMark = changeMark(board.cMark);
		writeln("You: ", board.cMark);
		writeln("Server: ", board.servMark);
		while(!winner) { //пока игра не окончена
			writeln();
			if(board.currentPlayer == board.cMark) 
			{
				do
				{
					write("Client (", board.cMark, "), enter row and column (ex: aB): ");
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
				
			}
			else {
				write("It's ", board.servMark, "'s turn, please, wait\n");
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
    }});
    runApplication();
}
