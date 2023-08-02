// Define your quiz questions and answers
const quizQuestions = [
    {
      question: "Which of the following statements is TRUE.",
      choices: ["A. It is possible to use Autoscaling with EBS, rather than EC2.", 
                "B. It is possible to configure an Autoscaling Group to repair degraded EBS volumes, without the need to terminate the EC2 instances.", 
                "C. You are able to attach mutiple EBS volumes to an EC2 instance.", 
                "D. You are able to at tach multiple EC2 instances to an EBS Volume."],
      correctAnswer: 2
    },
    {
      question: "How many Internet Gateways can you attach to your custom VPC?",
      choices: ["A. 3", "B. 5", "C. 4", "D. 1"],
      correctAnswer: 3
    },
    {
      question: "A company wants to self-manage a database environment. Which of the following should be adopted to fulfil this requirement?",
      choices: ["A. Use the DynamoDB service", 
                "B. Provision the database using the AWS RDS service", 
                "C. Provision the database using the AWS RDS service", 
                "D. Create an EC2 Instance and install the database service accordingly"],
      correctAnswer: 3
    },
    {
      question: "You have been asked to identify a service on AWS that is a durable object storage. Which of the services will this be?",
      choices: ["A. Elastic Compute Cloud (EC2)", 
                "B. Mobile Hub", 
                "C. Simple Service Storage (S3)",
                "D. Elastic File Service (EFS)"],
      correctAnswer: 2
    },
    {
      question: "What data formats are policy documents written in?",
      choices: ["A. yaml",
                "B. json",
                "C. xml",
                "D. pdf"],
      correctAnswer: 0
    },
    {
      question: "You need to restrict access to an S3 Bucket. Which of the following will you use to do so?",
      choices: ["A. CloudFront",
                "B. Identity Federation with Active Directory",
                "C. S3 Bucket Policy",
                "D. CloudWatch"],
      correctAnswer: 2
    },
    // Add more questions here
  ];
  
// DOM elements
const questionElement = document.getElementById("question");
const choicesElement = document.getElementById("choices");
const feedbackElement = document.getElementById("feedback");
const nextButton = document.getElementById("next-btn");
const backButton = document.getElementById("back-btn");
const scoreContainer = document.getElementById("score-container");

let currentQuestion = 0;
let score = 0;

// Load the current question
function loadQuestion() {
  const question = quizQuestions[currentQuestion];
  questionElement.textContent = question.question;

  choicesElement.innerHTML = "";
  question.choices.forEach((choice, index) => {
    const li = document.createElement("li");
    li.textContent = choice;
    li.addEventListener("mouseover", () => addShadow(li)); // Add shadow on mouseover
    li.addEventListener("mouseout", () => removeShadow(li)); // Remove shadow on mouseout
    li.addEventListener("click", () => confirmAnswer(index)); // Confirm answer on click
    choicesElement.appendChild(li);
  });

  feedbackElement.textContent = "";
  nextButton.disabled = true;
  backButton.disabled = currentQuestion === 0;
}

// Add shadow on mouseover
function addShadow(element) {
  element.style.boxShadow = "0 0 5px rgba(0, 0, 0, 0.3)";
}

// Remove shadow on mouseout
function removeShadow(element) {
  element.style.boxShadow = "none";
}

// Confirm the selected answer
function confirmAnswer(choiceIndex) {
  const question = quizQuestions[currentQuestion];
  const selectedChoice = choicesElement.children[choiceIndex];

  // Remove event listeners from other choices
  for (let i = 0; i < choicesElement.children.length; i++) {
    const choice = choicesElement.children[i];
    if (choice !== selectedChoice) {
      choice.removeEventListener("click", confirmAnswer);
    }
  }

  // Display confirmation feedback
  feedbackElement.innerHTML = `Selected: ${selectedChoice.textContent}<br><button onclick="checkAnswer(${choiceIndex})">Check Answer</button>`;
}

// Check the selected answer
function checkAnswer(choiceIndex) {
  const question = quizQuestions[currentQuestion];
  const selectedChoice = choicesElement.children[choiceIndex];

  if (choiceIndex === question.correctAnswer) {
    feedbackElement.textContent = "Correct!";
    score++;
  } else {
    feedbackElement.textContent = "Wrong!";
  }

  selectedChoice.style.backgroundColor = choiceIndex === question.correctAnswer ? "green" : "red"; // Highlight the selected choice

  nextButton.disabled = false;
}

// Move to the next question
function nextQuestion() {
  currentQuestion++;
  if (currentQuestion < quizQuestions.length) {
    loadQuestion();
  } else {
    showScore();
  }
}

// Move to the previous question
function previousQuestion() {
  currentQuestion--;
  loadQuestion();
}

// Display the final score
function showScore() {
  questionElement.textContent = `Quiz Completed! Your Score: ${score}/${quizQuestions.length}`;

  choicesElement.innerHTML = "";
  feedbackElement.textContent = getComplimentaryComment();

  nextButton.style.display = "none";
  backButton.style.display = "none";

  scoreContainer.style.display = "block";
}

// Generate a complimentary comment based on the score
function getComplimentaryComment() {
  const percentage = (score / quizQuestions.length) * 100;
  if (percentage === 100) {
    return "Congratulations! Perfect score!";
  } else if (percentage >= 80) {
    return "Great job! You did well!";
  } else if (percentage >= 60) {
    return "Good effort! Keep improving!";
  } else {
    return "You can do better! Keep learning!";
  }
}

// Event listeners
nextButton.addEventListener("click", nextQuestion);
backButton.addEventListener("click", previousQuestion);

// Start the quiz
loadQuestion();
