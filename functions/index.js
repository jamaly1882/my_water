const {setGlobalOptions} = require("firebase-functions");
const {onRequest} = require("firebase-functions/https");
const vision = require("@google-cloud/vision");

setGlobalOptions({maxInstances: 10});

const client = new vision.ImageAnnotatorClient();

exports.extractNumber = onRequest(async (req, res) => {

  try {

    const imageBase64 = req.body.image;

    if (!imageBase64) {
      res.status(400).json({
        error: "No image"
      });
      return;
    }


    const [result] = await client.textDetection({
      image: {
        content: imageBase64
      }
    });


    const text =
      result.textAnnotations?.[0]?.description || "";


    // استخراج الأرقام فقط
    const number = text.replace(/\D/g, "");


    res.json({
      number: number
    });


  } catch (error) {

    console.error(error);

    res.status(500).json({
      error: error.message
    });

  }

});