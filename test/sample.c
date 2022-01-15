#include <stdio.h>
int nested_checking(const char *buff_array)
{
    if(buff_array[0] == 'A'){
        if(buff_array[1] == 'B'){
            if(buff_array[2] == 'M'){
                return 4;
            }
            if(buff_array[2] == 'N'){
                return 5;
            }
        }
        else if(buff_array[1] == 'C'){
            if(buff_array[2] == 'D'){
                if(buff_array[3] == 'E'){
                    return 5;
                }
                if(buff_array[3] == 'F'){
                    return 6;
                }
            }
            else{
                return 1;
            }
        }
    }
    return 3;
}

int main(int argc,char** argv){
    // std::cout<<"What's your name?"<<std::endl;
    // std::string name;
    // std::cin>>name;
    // return nested_checking(name.c_str());
    
    int size = 5;
	char* buff = (char*)malloc(size);
    int ret;
	// read lines
	if(NULL != fgets(buff, size, stdin)) {
		ret = nested_checking(buff);
	}
	// free buff
	free(buff);
    return ret;
}