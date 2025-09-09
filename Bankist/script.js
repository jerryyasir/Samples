'use strict';

/////////////////////////////////////////////////
/////////////////////////////////////////////////
// BANKIST APP

// Data
const account1 = {
  owner: 'Jonas Schmedtmann',
  movements: [200, 450, -400, 3000, -650, -130, 70, 1300],
  interestRate: 1.2, // %
  pin: 1111,
};

const account2 = {
  owner: 'Jessica Davis',
  movements: [5000, 3400, -150, -790, -3210, -1000, 8500, -30],
  interestRate: 1.5,
  pin: 2222,
};

const account3 = {
  owner: 'Steven Thomas Williams',
  movements: [200, -200, 340, -300, -20, 50, 400, -460],
  interestRate: 0.7,
  pin: 3333,
};

const account4 = {
  owner: 'Sarah Smith',
  movements: [430, 1000, 700, 50, 90],
  interestRate: 1,
  pin: 4444,
};

const accounts = [account1, account2, account3, account4];

// Elements
const labelWelcome = document.querySelector('.welcome');
const labelDate = document.querySelector('.date');
const labelBalance = document.querySelector('.balance__value');
const labelSumIn = document.querySelector('.summary__value--in');
const labelSumOut = document.querySelector('.summary__value--out');
const labelSumInterest = document.querySelector('.summary__value--interest');
const labelTimer = document.querySelector('.timer');

const containerApp = document.querySelector('.app');
const containerMovements = document.querySelector('.movements');

const btnLogin = document.querySelector('.login__btn');
const btnTransfer = document.querySelector('.form__btn--transfer');
const btnLoan = document.querySelector('.form__btn--loan');
const btnClose = document.querySelector('.form__btn--close');
const btnSort = document.querySelector('.btn--sort');

const inputLoginUsername = document.querySelector('.login__input--user');
const inputLoginPin = document.querySelector('.login__input--pin');
const inputTransferTo = document.querySelector('.form__input--to');
const inputTransferAmount = document.querySelector('.form__input--amount');
const inputLoanAmount = document.querySelector('.form__input--loan-amount');
const inputCloseUsername = document.querySelector('.form__input--user');
const inputClosePin = document.querySelector('.form__input--pin');

const displayMovements = function (movements) {
  containerMovements.innerHTML = '';
  movements.forEach(function (mov, i)  {
    const type = mov > 0 ? 'deposit' : 'Withdrawal';
    const movementHtml = `
      <div class="movements__row">
        <div class="movements__type movements__type--${type}">
          ${i + 1}
        ${type}</div>
        <div class="movements__value">${mov}€</div>
      </div>`;
      containerMovements.insertAdjacentHTML('afterbegin', movementHtml);
  });
};

displayMovements(account1.movements);
console.log(containerMovements.innerHTML);
/////////////////////////////////////////////////
/////////////////////////////////////////////////
// LECTURES

// const currencies = new Map([
//   ['USD', 'United States dollar'],
//   ['EUR', 'Euro'],
//   ['GBP', 'Pound sterling'],
// ]);

const movements = [200, 450, -400, 3000, -650, -130, 70, 1300];

const JuliasData = [3, 5, 2, 12, 7];
const KateData = [4, 1, 15, 8, 3];

const checkDogs = function(JuliasData, KateData) {
  const DogsJuliaCorrected = JuliasData.slice();
  DogsJuliaCorrected.splice(0, 1);
  DogsJuliaCorrected.splice(-2);
  console.log(DogsJuliaCorrected);

  const dogs = DogsJuliaCorrected.concat(KateData);
  console.log(dogs);

  dogs.forEach(function(dog, i) {
    if(dog >= 3) {
      console.log(`Dog number ${i + 1} is an adult, and is ${dog} years old`);
    }else{
      console.log(`Dog number ${i + 1} is still a puppy 🐶`);
    }
  });
}

checkDogs(JuliasData, KateData);
//Map Creats New Array based on Existing Array

console.log(JuliasData);
const AddTwoToJuliaDogsAge = JuliasData.map(dog => dog+2);
console.log(AddTwoToJuliaDogsAge);

// const Assignments = [{
//   'FirstName': 'John',
//   'LastName': 'Smith',
//   'AssignmentId': 1234
// },
// {
//   'FirstName': 'Jane',
//   'LastName': 'Doe',
//   'AssignmentId': 5678
// }
// ];

// console.log(typeof Assignments);
// const AssignmentJson = JSON.stringify(Assignments);
// console.log(AssignmentJson);

// const assignmentsAdded1000 = Assignments.map(assignment => {
//   return {...assignment, AssignmentId: assignment.AssignmentId + 1000};  
// });
// console.log(assignmentsAdded1000);

// const AssignmentsForJohn = Assignments.filter(assignment => assignment.FirstName === 'John');
// console.log(AssignmentsForJohn);

// const total = Assignments.reduce((acc, assignment) => acc + assignment.AssignmentId, 0);
// console.log(total);

// const euroToUsd = 1.1;
// const movementsUSD = movements.map(mov => mov * euroToUsd);
// console.log(movementsUSD);

// const movementsUSDfor = [];
// for(const mov of movements) movementsUSDfor.push(mov * euroToUsd);
// console.log(movementsUSDfor);

// const movementDescription = movements.map(
//   (mov, i) =>
//     `Movment ${i + 1}: You ${mov > 0 ? 'deposited' :
//     'withdrew'} ${Math.abs(
//       mov
//     )}`
// );

// const JuliasDataMapped = JuliasData.map(
//   (dog, i) =>
//     `Dog number ${i + 1} is ${dog} years old`
// );
// console.log(JuliasDataMapped);

// const user = account1.owner;
// const userName = user.toLowerCase().split(' ');
// console.log(userName);
// const userInitials = userName.map(name => name[0]).join('');
// console.log(userInitials);

const createUserNames = function(accs) {
  accs.forEach(function(acc) {
    acc.userName = acc.owner
      .toLowerCase()
      .split(' ')
      .map(name => name[0])
      .join('');
  });
};

console.log(createUserNames(accounts));
console.log(accounts);

const deposits = movements.filter(function(mov) {
  return mov > 0
});

const dep1 = movements.filter((mov) => {
  return mov > 0
});
console.log(dep1)

const depositsFor = [];
deposits.forEach(function(mov) {
  if(mov > 0) depositsFor.push(mov);
});
console.log(depositsFor);

const withdrawls = movements.filter(mov => mov < 0);
console.log(withdrawls);

const getCountries = async function(countryName) {
  var requestUrl = 'https://restcountries.com/v3.1/name/' + countryName;
  const response = await fetch(requestUrl);
  const data = await response.json();
  return data;
};

const countryData= getCountries("pakistan");
countryData.then(data => console.log(data));

const arrayOfCountries = ["pakistan", "india", "canada"];
console.log(arrayOfCountries);
const arrayOfCountriesUpperCase =  arrayOfCountries.map(country => country.toUpperCase());
console.log(arrayOfCountriesUpperCase);

//Create a new Array as ArrayOfCountry and add additional property named Population.
const arrayOfCountriesWithPopulation =  arrayOfCountries.map(country => {
  return {
    name: country,
    population: country.length * 1000000
  };
});

const arrayOfReligion = ["Islam", "Hinduism", "Christianity"];

console.log(arrayOfCountriesWithPopulation);
const arrayOfCountriesWithReligion =  arrayOfCountriesWithPopulation.map(country => {
  return {
    ...country,
    // Pick a random religion by choosing a random valid index
    religion: arrayOfReligion[Math.floor(Math.random() * arrayOfReligion.length)]
  };
});
console.log(arrayOfCountriesWithReligion);
console.log(Math.random());
// Generate a Random number between 0 and 2 and get value from arrayOfReligion based on that Random Number.
const randomIndex = Math.floor(Math.random() * 3); // 0, 1, or 2
const randomReligion = arrayOfReligion[randomIndex];
console.log('Random index (0..2):', randomIndex);
console.log('Random religion:', randomReligion);


const balance = movements.reduce((acc, cur, i, arr) =>
{
  console.log(`Iteration ${i}: ${acc}`);
  return acc + cur
}, 0)

labelBalance.textContent = `${balance} EUR`;

const maxValue = movements.reduce((acc, mov) => {
  if(acc > mov) return acc;
  else return mov;
},movements[0]);
console.log(maxValue);


const arrOfDogs = [5, 2, 4, 1, 15, 8, 3];
const ArrayDogsFormatted = arrOfDogs.map(dog => dog * 2).filter(dog => dog >= 10).reduce((acc, dog) => acc + dog, 0);

console.log(ArrayDogsFormatted);
