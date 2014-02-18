<?
/*
Copyright (c) 2009 Drew LeSueur

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/


//$csv = file_get_contents($_GET['file']);

//pass a csv string, get a php array

function csv_to_array($csv)
{
$len = strlen($csv);


$table = array();
$cur_row = array();
$cur_val = "";
$state = "first item";


for ($i = 0; $i < $len; $i++)
{
	//sleep(1000);
$ch = substr($csv,$i,1);
	if ($state == "first item")
	{
		if ($ch == '"')
		{
			$state = "we're quoted hea";
		}
		elseif ($ch == ",") //empty
		{
			$cur_row[] = ""; //done with first one
			$cur_val = "";
			$state = "first item";
		}
		elseif ($ch == "\n")
		{
			$cur_row[] = $cur_val;
			$table[] = $cur_row;
			$cur_row = array();
			$cur_val = "";
			$state = "first item";
		}
		elseif ($ch == "\r")
		{
			$state = "wait for a line feed, if so close out row!";
		}
		else
		{
			$cur_val .= $ch;
			$state = "gather not quote";
		}
		
	}

	elseif ($state == "we're quoted hea")
	{
		if ($ch == '"')
		{
			$state = "potential end quote found";
		}
		else
		{
			$cur_val .= $ch;
		}
	}
	elseif ($state == "potential end quote found")
	{
		if ($ch == '"')
		{
			$cur_val .= '"';
			$state = "we're quoted hea";
		}
		elseif ($ch == ',')
		{
			$cur_row[] = $cur_val;
			$cur_val = "";
			$state = "first item";
		}
		elseif ($ch == "\n")
		{
			$cur_row[] = $cur_val;
			$table[] = $cur_row;
			$cur_row = array();
			$cur_val = "";
			$state = "first item";
		}
		elseif ($ch == "\r")
		{
			$state = "wait for a line feed, if so close out row!";
		}
		else
		{
			$cur_val .= $ch;
			$state = "we're quoted hea";
		}

	}
	elseif ($state == "wait for a line feed, if so close out row!")
	{
		if ($ch == "\n")
		{
			$cur_row[] = $cur_val;
			$cur_val = "";
			$table[] = $cur_row;
			$cur_row = array();
			$state = "first item";

		}
		else
		{
			$cur_row[] = $cur_val;
			$table[] = $cur_row;
			$cur_row = array();
			$cur_val = $ch;
			$state = "gather not quote";
		}	
	}

	elseif ($state == "gather not quote")
	{
		if ($ch == ",")
		{
			$cur_row[] = $cur_val;
			$cur_val = "";
			$state = "first item";
			
		}
		elseif ($ch == "\n")
		{
			$cur_row[] = $cur_val;
			$table[] = $cur_row;
			$cur_row = array();
			$cur_val = "";
			$state = "first item";
		}
		elseif ($ch == "\r")
		{
			$state = "wait for a line feed, if so close out row!";
		}
		else
		{
			$cur_val .= $ch;
		}
	}

}

return $table;
}
?>