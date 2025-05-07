iOS `Photos` App
============================================

## Code Interview Process 

Please follow the task requirements, the component style should be matched the screenshot.

You have one week to do it.

- Create a new branch based on master instead of fork.
- [Create the PR](../../pulls) when you finished.
- Please communicate in English. Do not use any other languages in your Code, especially code and commits' comments.

If you have any questions, please feel free to [raise the issue](../../issues) in the repo. We're glad to help you.

Please let me know when your PR's ready for review.

## Notice:
Your code will be reviewed and scored by the other developers of the team you will join.

Your code will have higher score if:

1. You split the task into smaller tasks, complete them one by one, and commit them in different git commits with proper commit messages 
2. The code is clean and easy to read and understand
3. The variable and function names are considered carefully
4. Small and meaningful functions for complex logic
5. No typo and has good code format
6. Meaningful, carefully organized test cases covered most of the important functionality
7. Provide proper/valuable comments, but only when it's necessary (in code and/or in github PR). Try improving the code to avoid un-necessary comments. 

## Task

Implement the `Photos List` page and `Photo Detail` page of the `Photos` app.

1. `SwiftUI` is our first choice, but you can use `UIKit` if you want.
2. You can use 3rd party libraries if you need.
3. provide proper comments in code (and only when it's necessary) 
4. show your best practise
5. use github pull request to submit your code

You can change any code in codebase to make it better.

## Requirement:
1. Implement the `Photos List` page:
	1. You should get all resouces and texts from the following end-point: https://jsonplaceholder.typicode.com/photos. 
		1. Tips: if cannot download the image from the `via.placeholder.com`, you can try to replace the `via.placeholder.com` with `dummyimage.com` locally.
		2. For example: https://via.placeholder.com/600/92c952 -> https://dummyimage.com/600/92c952
	2. Implement the basic UI:
	    1. Precise pixel-level alignment is not required; 
	    2. feel free to optimize the UI based on your understanding;
	3. Implement the functionality: 
	    1. Search;
	    2. Switch between all list and the favorites list;
2. Implement the `Photo Detail` page:
    1. Implement the basic UI:
        1. Precise pixel-level alignment is not required; 
        2. feel free to optimize the UI based on your understanding;
    2. Implement the functionality: 
    	1. Add to favorites;
    	2. Remove from favorites;
3. Implement the unit tests for your models;
4. (<mark>**Optional**</mark>) Implement a simple automation test for this app;

![Photos List](./Images/search.gif)
![Photos Detail](./Images/favorite.gif)

## Install
Open the `Photos.xcodeproj` in the root directory with Xcode.
