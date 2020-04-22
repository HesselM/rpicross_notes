#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <iostream>

using namespace cv;
using namespace std;

int main( int argc, char** argv )
{
    if( argc != 2) {
        cout <<" Usage: display_image ImageToLoadAndDisplay" << endl;
        return -1;
    }
        
    // Read image
    Mat image;
    image = imread( argv[1], IMREAD_COLOR);
    
    // Check for invalid input
    if( image.empty() ) {
        cout <<  "Could not open or find the image" << std::endl ;
        return -1;
    }

    // Create a window for display and show our image inside it.
    namedWindow( "Display window", WINDOW_AUTOSIZE );
    imshow( "Display window", image );
    
    // Wait for a keystroke in the window
    waitKey(0);
    return 0;
}
