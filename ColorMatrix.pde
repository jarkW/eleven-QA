class ColorMatrix
{
    // This is based largely off the quasimodo ColorMatrix.as in src/com/quasimodo/geom/filters

    // Final array containing sum of colour conversions
    float[] matrixArray = new float[20];
    
    // Array used to story current action/method
    float[] methodArray = new float[20];

    
     /*
    float [] matrix = {
                     //r  g  b  a  offset
                       0, 0, 0, 0, 0, //r
                       0, 0, 0, 0, 0, //g
                       0, 0, 0, 0, 0, //b
                       0, 0, 0, 0, 0, //a
                      };
    */
                   
    final float [] IDENTITY = {1,0,0,0,0,
                               0,1,0,0,0,
                               0,0,1,0,0,
                               0,0,0,1,0};  
                               
    // RGB to Luminance conversion constants as found on
    // Charles A. Poynton's colorspace-faq:
    // http://www.faqs.org/faqs/graphics/colorspace-faq/      
    final float LUMA_R = 0.212671;
    final float LUMA_G = 0.71516;
    final float LUMA_B = 0.072169;
    
    // constructor/initialise fields

    public ColorMatrix(int geoTintColor, int geoTintAmount, int geoContrast, int geoSaturation, int geoBrightness)
    {
        // Use the code in getFilter() in src/com/tinyspeck/engine/filters/ColorMatrix.as as basis 
        //var cm:com.quasimondo.geom.ColorMatrix = new com.quasimondo.geom.ColorMatrix();
        // Set up matrix to contain identity elements
        init();
        
        //cm.colorize(tintColor, tintAmount/100);
        colorize(geoTintColor, (float)geoTintAmount/100);
        
        //cm.adjustContrast(contrastValue/100);
        adjustContrast((float)geoContrast/100);
        
        //cm.adjustSaturation(saturationValue/100 + 1);
        adjustSaturation(((float)geoSaturation/100) + 1);
        
        //cm.adjustBrightness(brightnessValue);
        adjustBrightness((float)geoBrightness);
        
        //debugStructure("final matrix is ", matrixArray);   
    }
    
    // Applies the tint indicated by the colour.
    // Tint amount is in range 0-1
    void colorize(int tintValue, float tintAmount)
    {
        float r;
        float g;
        float b;
        float invTintAmount;
        
        // extract the rgb values 
        r = (float)( ( tintValue >> 16 ) & 0xFF )/0xFF;
        g = (float)( ( tintValue >> 8  ) & 0xFF )/0xFF;
        b = (float)(   tintValue         & 0xFF )/0xFF;
        invTintAmount = (1 - tintAmount);
        
        // Initialise the method array
        copyMatrix(IDENTITY, methodArray);
        
        // Set up the method array with tint settings and then apply to matrixArray
            
        //    concat([(inv_amount + ((amount * r) * LUMA_R)), ((amount * r) * LUMA_G), ((amount * r) * LUMA_B), 0, 0, 
        //        ((amount * g) * LUMA_R), (inv_amount + ((amount * g) * LUMA_G)), ((amount * g) * LUMA_B), 0, 0, 
        //        ((amount * b) * LUMA_R), ((amount * b) * LUMA_G), (inv_amount + ((amount * b) * LUMA_B)), 0, 0, 
        //        0, 0, 0, 1, 0]);
        methodArray[0] = invTintAmount + ((tintAmount * r) * LUMA_R);  
        methodArray[1] = (tintAmount * r) * LUMA_G;
        methodArray[2] = (tintAmount * r) * LUMA_B;
        methodArray[5] = (tintAmount * g) * LUMA_R;
        methodArray[6] = invTintAmount + ((tintAmount * g) * LUMA_G);
        methodArray[7] = (tintAmount * g) * LUMA_B;
        methodArray[10] = (tintAmount * b) * LUMA_R;
        methodArray[11] = (tintAmount * b) * LUMA_G;
        methodArray[12] = invTintAmount + ((tintAmount * b) * LUMA_B);
        matrixConcat(methodArray);
                               
    }
  
        
    // Changes the contrast
    // Takes s in the range -1.0 to 1.0:
    //    -1.0 means no contrast (grey)
    //    0 means no change
    //    1.0 is high contrast
    void adjustContrast(float contrastValue)
    {       
        contrastValue += 1;
         
        // Initialise the method array
        copyMatrix(IDENTITY, methodArray);
        
        // Set up the method array with contrast settings and then apply to matrixArray
        //    concat([r, 0, 0, 0, (128 * (1 - r)), 
        //        0, g, 0, 0, (128 * (1 - g)), 
        //        0, 0, b, 0, (128 * (1 - b)), 
        //        0, 0, 0, 1, 0]);      
        methodArray[0] = contrastValue;               
        methodArray[4] = 128 * (1 - contrastValue);
        methodArray[6] = contrastValue;
        methodArray[9] = 128 * (1 - contrastValue);
        methodArray[12] = contrastValue;
        methodArray[14] = 128 * (1 - contrastValue);
        matrixConcat(methodArray);
    }
 
    // changes the saturation
    // Takes s in the range 0.0 to 2.0 where 
    //      0.0 means 0% Saturation
    //      0.5 means 50% Saturation
    //      1.0 is 100% Saturation (aka no change)
    //      2.0 is 200% Saturation
    // Other values outside of this range are possible
    //     -1.0 will invert the hue but keep the luminance        
    void adjustSaturation(float saturationValue)
    {        
        float saturationValueInverse;
        float irlum;
        float iglum;
        float iblum;
            
        saturationValueInverse = 1 - saturationValue;            
        irlum = saturationValueInverse * LUMA_R;
        iglum = saturationValueInverse * LUMA_G;
        iblum = saturationValueInverse * LUMA_B;
            
        // Initialise the method array
        copyMatrix(IDENTITY, methodArray);
        
        // Set up the method array with saturation settings and then apply to matrixArray
        //    concat([(irlum + s), iglum, iblum, 0, 0, 
        //        irlum, (iglum + s), iblum, 0, 0, 
        //        irlum, iglum, (iblum + s), 0, 0, 
        //        0, 0, 0, 1, 0]);
        methodArray[0] = irlum + saturationValue;
        methodArray[1] = iglum;
        methodArray[2] = iblum;
        methodArray[5] = irlum;
        methodArray[6] = iglum + saturationValue;
        methodArray[7] = iblum;
        methodArray[10] = irlum;
        methodArray[11] = iglum;
        methodArray[12] = iblum + saturationValue;
        matrixConcat(methodArray);        
    } 
        
    // Adjusts the brightness - takes value s which can be -100 to 100
    void adjustBrightness(float brightnessValue)
    {       
        // Initialise the method array
        copyMatrix(IDENTITY, methodArray);
        
        // Set up the method array with brightness settings and then apply to matrixArray
        //            concat([1, 0, 0, 0, geoBrightness, 
        //        0, 1, 0, 0, geoBrightness, 
        //        0, 0, 1, 0, geoBrightness, 
        //        0, 0, 0, 1, 0]);
        methodArray[4] = brightnessValue;
        methodArray[9] = brightnessValue;
        methodArray[14] = brightnessValue;
        matrixConcat(methodArray);
    }
    
    private void init()
    {
        //matrixArray = identityArray.concat();
        copyMatrix(IDENTITY, matrixArray);
    }
    
    void copyMatrix(float [] source, float[] target)
    {
        // This allows a matrix to be copied and saved in a different variable
        for (int i = 0; i < 20; i++)
        {
            target[i] = source[i];
        }
    }

    void matrixConcat(float [] matArray)
    {
        // Replacement for concat
        // Applies the actions specified in mat to matrix, saving result in matrix
        // Allows matrix operations to be queued up
        float [] temp = new float[20];
        int i = 0;
        int x;
        int y;
        
        //debugStructure("Enter matrixConcat with matArray = ", matArray);    
        //debugStructure("Enter matrixConcat with matrixArray = ", matrixArray);
        
        for (y = 0; y < 4; y++)
        {                
            for (x = 0; x < 5; x++)
            {
                temp[i+x] = (matArray[i] * matrixArray[x]) + 
                            (matArray[i+1] * matrixArray[x+5]) + 
                            (matArray[i+2] * matrixArray[x+10]) + 
                            (matArray[i+3] * matrixArray[x+15]) +
                            (x == 4 ? matArray[i+4] : 0);
            }
            i+=5;
        }
        // save result back into matrixArray        
        copyMatrix(temp, matrixArray);
        //debugStructure("Leave matrixConcat with matrixArray = ", matrixArray);    
    }
    
    
    void debugStructure(String msg, float [] array)
    {
        printToFile.printDebugLine(this, msg + array[0] + "," + array[1] + "," + array[2] + "," + array[3] + "," + array[4], 1);
        printToFile.printDebugLine(this, msg + array[5] + "," + array[6] + "," + array[7] + "," + array[8] + "," + array[9], 1);
        printToFile.printDebugLine(this, msg + array[10] + "," + array[11] + "," + array[12] + "," + array[13] + "," + array[14], 1);
        printToFile.printDebugLine(this, msg + array[15] + "," + array[16] + "," + array[17] + "," + array[18] + "," + array[19], 1);
    }
        
    public void dumpMatrix()
    {
        debugStructure("MatrixArray is ", matrixArray);
    }
    
    public color calcNewRPGA(float srcR, float srcG, float srcB, float srcA)
    {
        // Applies the colour matrix to the input RGB and returns the converted colour
        float r;
        float g;
        float b;
        float a;
        color newColour;
        
        r = (matrixArray[0]  * srcR) + (matrixArray[1]  * srcG) + (matrixArray[2]  * srcB) + (matrixArray[3]  * srcA) + matrixArray[4];
        g = (matrixArray[5]  * srcR) + (matrixArray[6]  * srcG) + (matrixArray[7]  * srcB) + (matrixArray[8]  * srcA) + matrixArray[9];
        b = (matrixArray[10] * srcR) + (matrixArray[11] * srcG) + (matrixArray[12] * srcB) + (matrixArray[13] * srcA) + matrixArray[14];
        a = (matrixArray[15] * srcR) + (matrixArray[16] * srcG) + (matrixArray[17] * srcB) + (matrixArray[18] * srcA) + matrixArray[19];
        
        // Ensure values are valid
        r = max(0, r);
        r = min(255, r);
        g = max(0, g);
        g = min(255, g);        
        b = max(0, b);
        b = min(255, b);
        a = max(0, a);
        a = min(255, a);
        
        newColour = color(r, g, b, a);
        return newColour;
    }
}